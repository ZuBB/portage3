#!/usr/bin/env ruby

current_dir = File.dirname(__FILE__)
$:.push File.expand_path(File.join(current_dir, '..', 'lib'))

require 'net/ftp'
require 'net/http'
require 'portage3'
require 'optparse'

# http://goo.gl/tPiDyr
require 'addressable/uri'
class URI::Parser
    def split url
        a = Addressable::URI::parse url
        [a.scheme, a.userinfo, a.host, a.port, nil, a.path, nil, a.query, a.fragment]
    end
end

SQL_QUERY2 = 'select homepage, null from ebuild_homepages'
SQL_QUERY3 = 'UPDATE ebuild_homepages SET status = ?, notice = ? WHERE homepage = ?;'

def process_item(homepage)
    if /^http/ =~ homepage
        result = check_http_path(homepage)
    elsif /^ftp/ =~ homepage
        return #check_ftp_path(row[1])
    else
        result = {
            'exception' => 'can\'t handle this type of URL',
            'result'    => false
        }
    end

    @homepages[homepage] = result
end

def check_http_path(url)
    result = native_http_check(url)
    return if result['result']

    needs_recheck =
        case
        when result['code'].start_with?('3') && (result['message'] =~ URI::regexp).nil?
            then false
        when result['code'].start_with?('3') && !(result['message'] =~ URI::regexp).nil?
            then true
        when result['code'] != '404'
            then true
        end

    result.merge!(wget_http_check(url)) if needs_recheck
    result
end

def native_http_check(url)
    result = {}
    parsed_url = URI.parse(url)
    req = Net::HTTP.new(parsed_url.host, parsed_url.port)

    req.ssl_timeout      = 15
    req.open_timeout     = 15
    req.read_timeout     = 15
    req.continue_timeout = 15

    if url.start_with?('https')
        req.use_ssl = true
        req.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end

    begin
        path = '/' + parsed_url.path
        res = req.request_get(path)
        result['result'] = res.code.start_with?('2')

        unless result['result']
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

def wget_http_check(url)
    result = {}
    output = `wget -Snv -t 1 -T 30 '#{url}' -O /dev/null 2>&1`.split("\n")

    status_index = output.index { |line| /^\s+Status/ =~ line }
    http_index = output.index { |line| /^\s+HTTP/ =~ line }
    valid_index = status_index || http_index

    if valid_index
        status = output[valid_index].split.drop(1)
        result['code'] = status[0]
        result['message'] = status[1..-1].join(' ')
        result['result'] = result['code'].start_with?('2')
        result.delete('exception') if result['result']
    else
        result['result'] = false
    end

    result
end

def check_ftp_path(url)
    url = URI.parse(url)
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

    opts.on("-t", "--threads NUMBER", "Use specified number of threads") do |value|
        options["threads"] = value.to_i
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
    options['threads'] = 1
elsif options['limit'].nil? == false
    options['threads'] = (options['limit'] / 2).floor
elsif options['threads'].nil?
    options['threads'] = 64
end

Thread.abort_on_exception = true
pool = Array.new(options['threads']) do |i|
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

