#
# A bit extended standart logger module
#
# Initial Author: Vasyl Zuzyak, 04/10/12
# Latest Modification: Vasyl Zuzyak, ...
#
require 'logger'

class Portage3::Logger
    include Portage3::Server

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

    PORT = 8127
    EOT = 'LOG:EOT'
    EOS = 'LOG:EOS'
    EXT = "log"

    @@dummy_client = nil

    def initialize
        @log_dir   = nil
        @loggers   = {}
        @semaphore = Mutex.new
        @log_tasks = Queue.new
        @completed_logs = {}

        @processing_thread = Thread.new { process_log_data }
        server = TCPServer.new('localhost', Portage3::Logger::PORT)
        loop do
            Thread.start(server.accept) do |connection|
                process_connection(connection)
            end
        end
    end

    def set_log_dir(log_dir)
        return true unless @log_dir.nil?
        return false if log_dir.nil?
        return false if log_dir.empty?

        db_name = File.basename(log_dir, '.' + Portage3::Database::EXT)
        log_dir = File.join(Utils.get_log_home, db_name)
        Dir.mkdir(log_dir) unless File.exist?(log_dir)

        return false unless File.directory?(log_dir)
        return false unless File.writable?(log_dir)

        @log_dir = log_dir
        return true
    end

    def init_device(params)
        unless (log_file = get_logfile(params))
            return false unless params.has_key?('dummy')
        end

        if params['dummy']
            log_file = '/dev/null'
        else
            @completed_logs[params['id']] = Queue.new
        end

        logger = Logger.new(log_file)
        logger.formatter = SimpleLog.new
        logger.level = params["debug"] ? Logger::DEBUG : Logger::INFO
        @semaphore.synchronize { @loggers[params['id']] = logger }

        true
    end

    def get_logfile(params)
        return false if @log_dir.nil?

        return false if params['id'].nil?
        return false if params['id'].empty?

        return false if params["file"].nil?
        return false if params["file"].empty?

        log_file_name = params["file"].match(/[^:]+$/).to_s.downcase
        log_file_name = log_file_name.sub(/^task_/, '') + '.' + EXT
        log_file_path = File.join(@log_dir, log_file_name)

        if File.exist?(log_file_path)
            mtime_str = File.mtime(log_file_path).strftime(Utils::TIMESTAMP)
            log_file_path_bak = log_file_path.dup + '.' + mtime_str + '.bak'
            File.rename(log_file_path, log_file_path_bak)
        end

        return log_file_path
    end

    def add_data4logging(item)
        @log_tasks << item
    end

    def close_logger(device)
        @loggers[device].info('going to close log device')
        @loggers[device].close
        @semaphore.synchronize { @loggers.delete(device) }
        @completed_logs[device] << 1 if @completed_logs.has_key?(device)
    end

    def wait_loggers_while_close
        # TODO do we need a timeout here?
        @completed_logs.each_value { |queue| queue.pop }
    end

    def process_log_data
        while true
            device, message, severity = *@log_tasks.pop

            if message == EOT
                close_logger(device)
                next
            end

            break if message == EOS

            @loggers[device].add(severity, message)
        end
    end

    def self.start_server
        unless Utils.port_open?(PORT)
            pid = fork { self.new }
            Process.detach(pid)
            # need to wait a bit
            # accessing a server immediately after its start causes error
            sleep(0.2)
            pid
        else
            STDOUT.puts 'previous logger server still running'
        end

        if @@dummy_client.nil?
            @@dummy_client = Portage3::Logger.get_client({'dummy' => true})
        end
    end

    def self.shutdown_server
        unless @@dummy_client.nil?
            @@dummy_client.shutdown_server
           #@@dummy_client = nil
        end
    end

    def self.get_client(params)
        Client.new(params)
    end
end

class Portage3::Logger::Client < Portage3::Client
    def initialize(params = {})
        # TODO hardcoded port & host
        super("localhost", Portage3::Logger::PORT, params)

        @tmp_id = nil

        # TODO also need to handle case when socket was not created
        unless get('init_device', params)
           STDOUT.puts "'get_logger': Required parameters missed!"
           #STDOUT.puts "'get_logger': Required parameters missed!"\
               #"\nSTDOUT will be used"
           #@logger = Logger.new(STDOUT)
        end

        self
    end

    def set_log_dir(log_dir)
        put('set_log_dir', log_dir)
    end

    def unknown(message) log(message, Logger::UNKNOWN) end
    def fatal(message) log(message, Logger::FATAL) end
    def error(message) log(message, Logger::ERROR) end
    def warn(message) log(message, Logger::WARN) end
    def info(message) log(message, Logger::INFO) end
    def debug(message) log(message, Logger::DEBUG) end

    def group_log(messages)
        messages.each { |message|
            message, priority, id = *message
            @tmp_id = id
            log(message, priority || Logger::INFO)
        }

        @tmp_id = nil
    end

    def log_info_block(message)
        group_log(["#{'-' * 50}", message, "#{'-' * 50}"])
    end

    def finish_logging
        info(Portage3::Logger::EOT)
        close
    end

    def shutdown_server
        put('wait_loggers_while_close')
        info(Portage3::Logger::EOS)
    end

    private
    def log(message, priority)
            put('add_data4logging', [@tmp_id || @id, message, priority])
    end
end

