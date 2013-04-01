#!/usr/bin/env ruby

current_dir = File.dirname(__FILE__)
$:.push File.expand_path(File.join(current_dir, '..', 'lib'))

require 'net/ftp'
require 'net/http'
require 'portage3'
require 'optparse'

HTTP_RECHECK_HOSTS = [
    'https://github.com',
    'https://gitorious.org',
    'http://gitorious.org',
    'http://www.emacswiki.org'
]
SQL_QUERY2 = 'select homepage, null from ebuild_homepages'
SQL_QUERY3 = 'UPDATE ebuild_homepages SET status = ?, notice = ? WHERE homepage = ?;'

def process_item(homepage)
    if /^http/ =~ homepage
        result = check_http_path(homepage)
    elsif /^ftp/ =~ homepage
        return #check_ftp_path(row[1])
    else
        result = {
            'exception' => 'cant handle this type of URI',
            'result'    => false
        }
    end

    @homepages[homepage] = result
end

def check_http_path(idx)
    result = native_http_check(idx)
    return if result['result']

    needs_recheck =
        case
        when result['code'].start_with?('3')
            then false
        when HTTP_RECHECK_HOSTS.any? { |host| idx.start_with?(host) }
            then true
        when result['code'] != '404'
            then true
        else
            result['notices'] = 'cant handle http error code/status'
            false
        end

    result.merge!(wget_http_check(idx, result)) if needs_recheck
    result
end

def native_http_check(idx)
    result = { 'notices' => nil }
    url = URI.parse(idx)
    req = Net::HTTP.new(url.host, url.port)

    req.ssl_timeout      = 15
    req.open_timeout     = 15
    req.read_timeout     = 15
    req.continue_timeout = 15

    if idx.start_with?('https')
        req.use_ssl = true
        req.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end

    begin
        path = '/' + url.path
        res = req.request_head(path)
        unless (result['result'] = res.code.start_with?('2'))
            result['code'] = res.code
            result['message'] = res.message
        end
    rescue Exception => e
        result['exception'] = e.message
        result['result'] = false
        result['code'] = '500'
    end

    result
end

def wget_http_check(idx, result_old)
    output = `wget -Snv -t 1 -T 30 '#{idx}' -O /dev/null 2>&1`.split("\n")
    result = { 'notices' => nil }

    status_index = output.index { |line| /^\s+Status/ =~ line }
    http_index = output.index { |line| /^\s+HTTP/ =~ line }
    valid_index = status_index || http_index

    if valid_index
        status = output[valid_index].split.drop(1)
        result['code'] = status[0]
        result['message'] = status[1]
        result['result'] = result['code'].start_with?('2')
    else
        old_exception = result_old['exception']
        new_exception = nil

        if output.empty?
            if old_exception == 'execution expired'
                new_exception = 'Connection timed out'
            else
                if old_exception.include?('-')
                    new_exception = old_exception.split('-')[0].strip
                else
                    new_exception = old_exception
                end
            end
        else
            notice = old_exception
            new_exception = output.join("\n")
        end

        result['exception'] = new_exception
        result['notice'] = notice
        result['result'] = false
    end

    result
end

def check_ftp_path(idx)
    url = URI.parse(idx)
    ftp = Net::FTP.new(url.host)
    ftp.login
    begin
        ftp.nlst(url.path)
    rescue Exception => e
        puts "FTP Exception message: #{e.message}"
        puts "for resource: #{e.message}"
        return false
    ensure
        ftp.close unless ftp.closed?
    end
    true
end

def get_status(result)
    return 'invalid' unless result.has_key?('code')

    return case
        when result['code'].start_with?('3')
            then 'needs love'
        when result['code'] == '404'
            then 'broken'
        else
            'needs attention'
        end
end

def get_error_message(result)
    output = []
    result.each { |key, value|
        next if key == 'result'
        next if value.nil? || value.empty?
        output << "#{key.capitalize}: #{value}"
    }
    output
end

options = {}

OptionParser.new do |opts|
    opts.banner = " Usage: check_ebuild_homepage.rb [options]"
    opts.separator "\n A script that checks homepage URL(s)"

    opts.on("-1", "--check-single STRING", "check single URL") do |value|
        options["single"] = true
        options["url"] = value
    end

    opts.on("-r", "--random", "Test random URLs") do |value|
        options["random"] = true
    end

    opts.on("-l", "--limit NUMBER", "Test limited number of URLs") do |value|
        options["limit"] = value.to_i
    end

    opts.on("-s", "--store", "Store results to db") do |value|
        options["store"] = true
    end

    opts.on("-p", "--[no-]print", "Print results") do |value|
        options["print"] = value
    end

    opts.on_tail("-h", "--help", "Show this message") do
        puts opts
        exit
    end
end.parse!

if options['single']
    @homepages = {options['url'] => nil}
    options['print'] = true
else
    params = []
    sql_query = SQL_QUERY2.clone

    if (options['random'])
        sql_query += ' ORDER BY RANDOM()'
    end

    if (options['limit'])
        sql_query += ' LIMIT ?'
        params << options['limit']
    end

    params.unshift(sql_query + ';')

    Portage3::Logger.start_server
    Portage3::Database.init(Utils.get_database)

    @database = Portage3::Database.get_client
    @homepages = Hash[@database.select(*params)]

    if options['store']
        options['store'] = @database.validate_query(SQL_QUERY3)
    end
end

jobs = Queue.new
@homepages.keys.each { |homepage| jobs << homepage }

if options['single']
    threads = 1
elsif options['limit'].nil? == false
    threads = (options['limit'] / 2).floor
else
    threads = 64
end

Thread.abort_on_exception = true
pool = Array.new(threads) do |i|
    Thread.new do
        while jobs.size > 0 do
            process_item(jobs.pop)
        end
    end
end

pool.each { |thread| thread.join }

@homepages.each do |homepage, result|
    next if !result || result['result']

    status = get_status(result)
    emessage = get_error_message(result)

    if options['store']
        @database.insert([status, emessage.join("\n"), homepage])
    end

    if options['print']
        emessage.unshift("Homepage: #{homepage}")
        emessage.unshift('='*10)
        puts emessage.join("\n")
    end
end

@database.shutdown_server if defined?(@database)

