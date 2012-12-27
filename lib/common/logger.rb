#
# A bit extended standart logger module
#
# Initial Author: Vasyl Zuzyak, 04/10/12
# Latest Modification: Vasyl Zuzyak, ...
#
require 'logger'

module Portage3::Logger
    # blog.grayproductions.net/articles/the_books_are_wrong_about_logger
    class SimpleLog < Logger::Formatter
        TIME_FORMAT = "%H:%M:%S.%6N"
        def call(severity, time, program_name, message)
            items = ['[' + time.strftime(TIME_FORMAT) + ']']
            items << (severity + ':').rjust(6, ' ')
            items << message + "\n"
            items.join(' ')
        end
    end

    EOT = 'LOG:EOT'
    EOS = 'LOG:EOS'
    EXT = "log"

    @@loggers = {}
    @@log_dir = nil
    @@dummy_client = nil
    @@completed_logs = {}
    @@log_tasks = Queue.new
    @@semaphore = Mutex.new

    def self.start_server
        @@thread = Thread.new do
           #Thread.current.priority = 2

            while true
                device, severity, message = *@@log_tasks.pop

                if message == EOT
                    self.close_logger(device)
                    next
                end

                break if message == EOS

                @@loggers[device].add(severity, message)
            end
        end

        @@dummy_client = Portage3::Logger.get_client({
            'dummy' => true,
            'id'    => self.name
        })
    end

    def self.set_log_dir(log_dir)
        return true unless @@log_dir.nil?
        return false if log_dir.nil?
        return false if log_dir.empty?

        db_name = File.basename(log_dir, '.' + Portage3::Database::EXT)
        log_dir = File.join(Utils.get_log_home, db_name)
        Dir.mkdir(log_dir) unless File.exist?(log_dir)

        return false unless File.directory?(log_dir)
        return false unless File.writable?(log_dir)

        @@log_dir = log_dir
        return true
    end

    def self.init_device(params)
        unless (log_file = self.get_logfile(params))
            return false unless params.has_key?('dummy')
        end

        if params['dummy']
            log_file = '/dev/null'
        else
            @@completed_logs[params['id']] = Queue.new
        end

        logger = Logger.new(log_file)
        logger.formatter = SimpleLog.new
        logger.level = params["debug"] ? Logger::DEBUG : Logger::INFO
        @@semaphore.synchronize { @@loggers[params['id']] = logger }

        true
    end

    def self.get_logfile(params)
        return false if @@log_dir.nil?

        return false if params['id'].nil?
        return false if params['id'].empty?

        return false if params["file"].nil?
        return false if params["file"].empty?

        log_file_name = params["file"].match(/[^:]+$/).to_s.downcase
        log_file_name = log_file_name.sub(/^task_/, '') + '.' + EXT
        log_file_path = File.join(@@log_dir, log_file_name)

        if File.exist?(log_file_path)
            mtime_str = File.mtime(log_file_path).strftime(Utils::TIMESTAMP)
            log_file_path_bak = log_file_path.dup + '.' + mtime_str + '.bak'
            File.rename(log_file_path, log_file_path_bak)
        end

        return log_file_path
    end

    def self.add_data4logging(item)
        @@log_tasks << item
    end

    def self.close_logger(device)
        @@loggers[device].info('going to close log device')
        @@loggers[device].close
        @@semaphore.synchronize { @@loggers.delete(device) }
        @@completed_logs[device] << 1 if @@completed_logs.has_key?(device)
    end

    def self.wait_loggers_while_close
        # TODO do we need a timeout here?
        @@completed_logs.each_value { |queue| queue.pop }
    end

    def self.shutdown_server
        @@dummy_client.shutdown_server
    end

    def self.get_client(params)
        Portage3::Logger::Client.new(params)
    end
end

class Portage3::Logger::Client
    SERVER = Portage3::Logger

    def initialize(params)
        #TODO missed id check
        unless params.is_a?(Hash)
            throw "'logger': passed value is not a Hash"
        end

        unless SERVER.init_device(params)
           throw "Logger::init_device: Required parameters was not passed!"
        end

        @id        = params['id']
        @tmp_id    = nil
        @semaphore = Mutex.new

        self
    end

    def set_log_dir(log_dir)
        SERVER.set_log_dir(log_dir)
    end

    def unknown(message) log(message, Logger::UNKNOWN) end
    def fatal(message) log(message, Logger::FATAL) end
    def error(message) log(message, Logger::ERROR) end
    def warn(message) log(message, Logger::WARN) end
    def info(message) log(message, Logger::INFO) end
    def debug(message) log(message, Logger::DEBUG) end

    def group_log(messages)
        @semaphore.synchronize {
            messages.each { |message|
                message, priority, id = *message
                @tmp_id = id
                log(message, priority || Logger::INFO)
            }
        }

        @tmp_id = nil
    end

    def log_info_block(message)
        group_log(["#{'-' * 50}", message, "#{'-' * 50}"])
    end

    def finish_logging
        info(Portage3::Logger::EOT)
    end

    def shutdown_server
        SERVER.wait_loggers_while_close
        info(Portage3::Logger::EOS)
    end

    private
    def log(message, priority)
        SERVER.add_data4logging([@tmp_id || @id, priority, message])
    end
end
