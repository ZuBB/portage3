#
# A bit extended standart logger module
#
# Initial Author: Vasyl Zuzyak, 04/10/12
# Latest Modification: Vasyl Zuzyak, ...
#
require 'logger'

module Portage3::Logger
    PORT = 8127
    EOT = 'LOG:EOT'
    EOS = 'LOG:EOS'
    EXT = ".log"

    @@dummy_client = nil

    # blog.grayproductions.net/articles/the_books_are_wrong_about_logger
    class SimpleLog < Logger::Formatter
        TIME_FORMAT = "%Y-%m-%d %H:%M:%S"
        def call(severity, time, program_name, message)
            items = ['[' + time.strftime(TIME_FORMAT) + ']']
            items << (severity + ':').rjust(6, ' ')
            items << message + "\n"
            items.join(' ')
        end
    end

    def self.start_server
        unless Utils.port_open?(PORT)
            pid = fork { Portage3::Logger::Server.new }
            Process.detach(pid)
            # need to wait a bit
            # accessing a server immediately after its start causes error
            sleep(0.2)
            pid
        else
            STDOUT.puts 'previous logger server still running'
        end

        self.start_dummy_client
    end

    def self.start_dummy_client
        if @@dummy_client.nil?
            @@dummy_client = Portage3::Logger::Client.new({
                'dummy' => true,
                'id'    => self.name
            })
        end
    end

    def self.stop_server
        unless @@dummy_client.nil?
            @@dummy_client.shutdown_server
            @@dummy_client = nil
        end
    end

    def self.get_logfile(params)
        return false if params['id'].nil?
        return false if params["file"].nil?
        return false if params["log_dir"].nil?

        return false if params['id'].empty?
        return false if params["file"].empty?
        return false if params["log_dir"].empty?

        db_name = File.basename(params["log_dir"], '.sqlite')
        log_dir = File.join(Utils.get_log_home, db_name)
        Dir.mkdir(log_dir) unless File.exist?(log_dir)

        return false unless File.directory?(log_dir)
        return false unless File.writable?(log_dir)

        log_file_name = params["file"].match(/[^:]+$/).to_s.downcase
        log_file_name = log_file_name.sub(/^task_/, '') + EXT
        log_file_path = File.join(log_dir, log_file_name)

        if File.exist?(log_file_path)
            mtime_str = File.mtime(log_file_path).strftime(Utils::TIMESTAMP)
            log_file_path_bak = log_file_path.dup + '.' + mtime_str + '.bak'
            File.rename(log_file_path, log_file_path_bak)
        end

        return log_file_path
    end
end

class Portage3::Logger::Server
    def initialize
        @loggers = {}
        @log_tasks = Queue.new

        Thread::abort_on_exception = true
        @log_thread = Thread.new { process_log_data }
        server = TCPServer.new('localhost', Portage3::Logger::PORT)
        loop do
            Thread.start(server.accept) do |connection|
                process_connection(connection)
            end
        end
    end

    def process_log_data
        while true
            device, message, severity = *@log_tasks.pop

            (close_logger(device); next) if message == Portage3::Logger::EOT
            break if message == Portage3::Logger::EOS

            @loggers[device].add(severity, message)
        end
    end

    def process_connection(connection)
        while accepted_string = connection.gets
            begin
                json_object = JSON.parse(accepted_string)
            rescue
                STDOUT.puts 'Logger: failed to parse json'
                STDOUT.puts accepted_string
                next
            end

            unless json_object.has_key?('action')
                STDOUT.puts 'no action'
                next
            end

            result = send(json_object['action'], *json_object['params'])

            if json_object['action'] == 'get_logger'
                connection.puts(JSON.generate({'result' => result}))
            end

            message = json_object['params'][0][1] rescue false

            if message == Portage3::Logger::EOS
                connection.close
                @log_thread.join
                Process.exit(true)
            end
        end
    end

    def get_logger(params)
        unless (log_file = Portage3::Logger.get_logfile(params))
            return false unless params.has_key?('dummy')
        end

        log_file = '/dev/null' if params['dummy']

        logger = Logger.new(log_file)
        logger.formatter = Portage3::Logger::SimpleLog.new
        logger.level = params["debug"] ? Logger::DEBUG : Logger::INFO
        @loggers[params['id']] = logger

        true
    end

    def add_data4log(item)
        @log_tasks << item
    end

    def close_logger(device)
        @loggers[device].close
        @loggers.delete(device)
    end
end

class Portage3::Logger::Client < Portage3::Client
    def initialize(params)
        super("localhost", Portage3::Logger::PORT)

        @id         = nil
        @tmp_id     = nil
        result      = nil

        if params.is_a?(Hash)
            result = get({
                'action' => 'get_logger',
                'params' => [params]
            })

            if result
                @id = params['id']
                result = self
            else
                STDOUT.puts "'get_logger': Required parameters missed!"
            end
        end

        result
    end

    def unknown(message)
        log(message, Logger::UNKNOWN)
    end

    def fatal(message)
        log(message, Logger::FATAL)
    end

    def error(message)
        log(message, Logger::ERROR)
    end

    def warn(message)
        log(message, Logger::WARN)
    end

    def info(message)
        log(message, Logger::INFO)
    end

    def debug(message)
        log(message, Logger::DEBUG)
    end

    def log_group(messages)
        messages.each { |message|
            message, priority, id = *message
            @tmp_id = id unless id.nil?
            log(message, priority || Logger::INFO)
        }

        @tmp_id = nil
    end

    def log_block(messages)
        info('-' * 50)
        log_group(messages)
        info('-' * 50)
    end

    def close(close_connection = true)
        info(Portage3::Logger::EOT)
        @socket.close if close_connection
    end

    def shutdown_server
        close(false)
        info(Portage3::Logger::EOS)
    end

    private
    def log(message, priority)
        put({
            'action' => 'add_data4log',
            'params' => [[@tmp_id || @id, message, priority]]
        })
    end
end

