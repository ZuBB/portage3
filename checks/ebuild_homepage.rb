#!/usr/bin/env ruby

current_dir = File.dirname(__FILE__)
$:.push File.expand_path(File.join(current_dir, '..', 'lib'))

require 'thread'
require 'net/ftp'
require 'net/http'
require 'portage3'

HTTP_OK_RESP_CODES = ['200', '301', '302', '307']
HTTP_RECHECK_RESP_CODES = ['400', '405', '500', '503']
HTTP_EXCP_STRS = [
    'Connection reset by peer',
    'end of file reached',
    'Connection refused',
    'execution expired',
]
HTTP_RECHECK_HOSTS = [
    'https://github.com',
    'https://gitorious.org',
    'http://gitorious.org',
    'http://www.emacswiki.org'
]
SQL_QUERY1 = <<-SQL
    select
        c.name || '/' || p.name || '-' || e.version as atom,
        ehs.homepage
    from categories c
    join packages p on p.category_id = c.id
    join ebuilds e on e.package_id = p.id
    join ebuilds_homepages eshs on eshs.ebuild_id = e.id
    join ebuild_homepages ehs on ehs.id = eshs.homepage_id
    order by e.id
SQL
SQL_QUERY2 = 'select homepage, null from ebuild_homepages'

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

    unless result['result']
        if result['code']
            if HTTP_RECHECK_HOSTS.any? { |host| idx.start_with?(host) }
                result.merge!(wget_http_check(idx, result.clone))
            elsif HTTP_RECHECK_RESP_CODES.include?(result['code'])
                result.merge!(wget_http_check(idx, result.clone))
            end
        elsif result['exception']
            if HTTP_EXCP_STRS.include?(result['exception'])
                result.merge!(wget_http_check(idx, result.clone))
            end
        else
            result['notices'] << 'cant handle http error code/status'
        end
    end

    result
end

def native_http_check(idx)
    result = { 'notices' => [] }
    url = URI.parse(idx)
    req = Net::HTTP.new(url.host, url.port)

    req.ssl_timeout = 15
    req.open_timeout = 15
    req.read_timeout = 15
    req.continue_timeout = 15
    if idx.start_with?('https')
        req.use_ssl = true
        req.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end

    begin
        path = '/' + url.path
        res = req.request_head(path)
        result['result'] = HTTP_OK_RESP_CODES.include?(res.code)

        unless result['result']
            result['code'] = res.code
            result['message'] = res.message
        end
    rescue Exception => e
        result['exception'] = e.message
        result['result'] = false
    end

    result
end

def wget_http_check(idx, result_old)
    output = `wget -Snv -t 1 -T 30 '#{idx}' -O /dev/null 2>&1`.split("\n")
    result = { 'notices' => [], 'wget' => true }

    status_index = output.index { |line| /^\s+Status/ =~ line }
    http_index = output.index { |line| /^\s+HTTP/ =~ line }

    if status_index.nil? == false
        status = output[status_index].split.drop(1)
        result['code'] = status[0]
        result['message'] = status[1]
        result['result'] = HTTP_OK_RESP_CODES.include?(result['code'])
    elsif http_index.nil? == false
        status = output[http_index].split.drop(1)
        result['code'] = status[0]
        result['message'] = status[1]
        result['result'] = HTTP_OK_RESP_CODES.include?(result['code'])
    elsif output.empty? == false
        result['exception'] = output.join(';')
    elsif output.empty?
        if result_old['exception'] == 'execution expired'
            result['notices'] << 'very likely its a \'Connection timed out\' error'
        else
            result['notices'] << 'wget headers issue'
        end
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

def print_details(ebuild, homepage)
    output = ['='*10]
    res = @homepages[homepage]
    return if res.nil?

    if res['result']
       #output << "ebuild: #{ebuild} - OK"
    else
        output << "ebuild: #{ebuild}"
        output << "homepage: #{homepage}"
        if res['exception']
            output << "Exception: #{res['exception']}"
        else
            output << "HTTP Response: #{res['code']} #{res['message']}"
        end
        if res.has_key?('notices') && !res['notices'].empty?
            output << "notices: #{res['notices']}"
        end
    end

    print (output << '').join("\n") if output.size > 1
end

Portage3::Logger.start_server
Portage3::Database.init(Utils.get_database)
database   = Portage3::Database.get_client
@homepages = Hash[database.select(SQL_QUERY2)]
@data      = Hash[database.select(SQL_QUERY1)]
@jobs      = Queue.new

@homepages.keys.each { |homepage| @jobs << homepage }

threads = 32
Thread.abort_on_exception = true

pool = Array.new(threads) do |i|
    Thread.new do
        Thread.current["name"] = "worker ##{i + 1}"
        Thread.current['count'] = 0

        while @jobs.size > 0 do
            process_item(@jobs.pop)
            Thread.current['count'] += 1
        end
    end
end

pool.each { |thread| thread.join }

@data.each_pair { |ebuild, homepage| print_details(ebuild, homepage) }

