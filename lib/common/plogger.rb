#
# A bit extended standart logger module
#
# Initial Author: Vasyl Zuzyak, 04/10/12
# Latest Modification: Vasyl Zuzyak, ...
#
require 'logger'

module PLogger
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

    LOGFILE_EXT = ".log"
    @log_tasks = Queue.new
    @semaphore = Mutex.new
    @loggers = {}
    @level = nil

    def self.init(params = {})
        unless self.is_basic_params_valid?(params)
            throw "PLogger::init: Required parameters was not passed!"
        end

        @thread = Thread.new do
            Thread.current.priority = 2
            Thread.current["name"] = "log worker"

            while true
                device, severity, message = *@log_tasks.pop

                if message == 'LOG:EOT'
                    self.close_logger(device)
                    next
                end

                break if message == 'LOG:EOS'

                @loggers[device].add(severity, message)
            end
        end
    end

    def self.is_basic_params_valid?(params)
        return false if params["path"].nil?
        return false if params["dir"].nil?

        return false if params["path"].empty?
        return false if params["dir"].empty?

        return false unless File.exist?(params["path"])
        return false unless File.writable?(params["path"])

        log_dir = File.join(params["path"], params["dir"])
        Dir.mkdir(log_dir) unless File.exist?(log_dir)

        @logs_home = params["path"]
        @log_dir = params["dir"]
        @level = params["level"] if params["level"]
        return true
    end

    def self.init_device(params = {})
        if (log_file = self.get_logfile(params)).nil?
            throw "PLogger::init_device: Required parameters was not passed!"
        end

        logger = Logger.new(log_file)
        logger.level = @level
        logger.formatter = SimpleLog.new
        @loggers[params['id']] = logger
    end

    def self.get_logfile(params)
        return nil if params['id'].empty?

        if !params["file"].nil? && !params["file"].empty?
            filename = params["file"].downcase
            filename.sub!(/^[^:]+::/, '')
            filename.sub!(/^task_/, '')
            log_file = filename + LOGFILE_EXT
            log_file_path = File.join(@logs_home, @log_dir, log_file)

            if File.exist?(log_file_path)
                log_file_path_bak = log_file_path.dup
                mtime = File.mtime(log_file_path_bak)
                mtime_str = mtime.strftime(Utils::TIMESTAMP)
                log_file_path_bak << '.' + mtime_str + '.bak'
                File.rename(log_file_path, log_file_path_bak)
            end

            return log_file_path
        elsif params['logfile']
            dir = File.dirname(params['logfile'])

            return nil unless File.exist?(dir)
            return nil unless File.writable?(dir)

            return params['logfile']
        else
            # TODO STDOUT
            return nil
        end
    end

    def self.log_info_block(id, message)
        self.group_log(id, [
            [1, "#{'-' * 70}"],
            [1, message],
            [1, "#{'-' * 70}"]
        ])
    end

    def self.group_log(id, messages)
        @semaphore.synchronize {
            messages.each { |message|
                @log_tasks << [id] + message
            }
        }
    end

    def self.unknown(id, message)
        @log_tasks << [id, 5, message]
    end

    def self.fatal(id, message)
        @log_tasks << [id, 4, message]
    end

    def self.error(id, message)
        @log_tasks << [id, 3, message]
    end

    def self.warn(id, message)
        @log_tasks << [id, 2, message]
    end

    def self.info(id, message)
        @log_tasks << [id, 1, message]
    end

    def self.debug(id, message)
        @log_tasks << [id, 0, message]
    end

    def self.end_of_task(id)
        self.info(id, 'LOG:EOT')
    end

    def self.close_logger(device)
        @loggers[device].close
        @loggers.delete(device)
    end

    def self.close
        sleep(0.2) while !@loggers.empty?
        self.info(nil, 'LOG:EOS')
        @thread.join
    end
end
