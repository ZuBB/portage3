#!/usr/bin/env ruby

current_dir = File.dirname(__FILE__)
$:.push File.expand_path(File.join(current_dir, '..', 'lib'))

require 'thread'
require 'net/ftp'
require 'net/http'
require 'portage3'

HTTP_OK_RESP_CODES = ['200', '301', '302']
HTTP_RECHECK_RESP_CODES = ['503', '405', '500']
HTTP_EXCP_STRS = [
    'Connection reset by peer',
    'end of file reached',
    'Connection refused',
    'Timeout::Error',
    'execution expired',
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

def process_item(row)
    if /^http/ =~ row[1]
        have_results = check_http_path(row[1])
    elsif /^ftp/ =~ row[1]
        return
        #check_ftp_path(row[1])
    else
        @semaphore.synchronize {
            @homepages << row[1]
            @results[row[1]] = {
                'notices' => ['cant handle this type of URI'],
                'result'  => false
            }
        }
        have_results = true
    end

    if have_results
        print_details(row)
    else
        @jobs << row
    end
end

def check_http_path(idx)
    if @homepages.include?(idx)
        return @results[idx]
    end

    if @semaphore.synchronize { @checking.include?(idx) }
        return false
    end

    @semaphore.synchronize {
        @checking << idx
    }

    result = native_http_check(idx)
    result['notices'] = []

    unless result['result']
        if result['code']
            if HTTP_RECHECK_RESP_CODES.include?(result['code'])
                result.merge!(wget_http_check(idx))
            end
        elsif result['exception']
            if HTTP_EXCP_STRS.include?(result['exception'])
                result.merge!(wget_http_check(idx))
            end
        else
            result['notices'] << 'cant handle http error code/status'
        end
    end

    @semaphore.synchronize {
        @homepages << idx
        @results[idx] = result
        @checking.delete_if {|x| x == idx }
    }

    true
end

def native_http_check(idx)
    result = {}
    url = URI.parse(idx)
    req = Net::HTTP.new(url.host, url.port)

    req.ssl_timeout = 20
    req.open_timeout = 20
    req.read_timeout = 20
    req.continue_timeout = 20
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

def wget_http_check(idx)
    output = `wget -Sq -t 1 -T 60 #{idx} -O /dev/null 2>&1`.split("\n")
    result = { 'notices' => [], 'wget' => true }

    status_index = output.index { |line| /\s+Status/ =~ line }
    http_index = output.index { |line| /\s+HTTP/ =~ line }

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
    else
        result['notices'] << 'wget headers issue'
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

def print_details(row)
    output = ['='*10]
    res = @results[row[1]]

    if res['result']
        output << "ebuild: #{row[0]} - OK"
    else
        output << "ebuild: #{row[0]}"
        output << "homepage: #{row[1]}"
        if res['exception']
            output << "Exception: #{res['exception']}"
        else
            output << "HTTP Response: #{res['code']} #{res['message']}"
        end
        output << "notices: #{res['notices']}" unless res['notices'].empty?
    end

    print (output << '').join("\n")
end

Portage3::Logger.start_server
Portage3::Database.init(Utils.get_database)
database   = Portage3::Database.get_client
data       = database.select(SQL_QUERY1)
@results   = Hash[database.select(SQL_QUERY2)]
@semaphore = Mutex.new
@jobs      = Queue.new
@homepages = []
@checking  = []

#data = [
    #['app-admin/fetchlog-0.94', 'http://fetchlog.sourceforge.net/'],
    #['app-accessibility/emacspeak-ss-1.9.1', 'http://leb.net/blinux/'],
#]

data.each { |row| @jobs << row }

threads = 24
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

