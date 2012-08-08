#
# A bit extended standart logger module
#
# Initial Author: Vasyl Zuzyak, 04/10/12
# Latest Modification: Vasyl Zuzyak, ...
#
require 'logger'
require 'thread'

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
    @log_file = nil
    @logger = nil

    def self.init(params = {})
        if (@log_file = self.get_logfile(params)).nil?
            throw "Required parameters was not passed!"
        end

        @logger = Logger.new(@log_file)
        @logger.level = params["level"] if params["level"]
        @logger.formatter = SimpleLog.new
        @thread = Thread.new do
            Thread.current.priority = 2
            Thread.current["name"] = "log worker"
            while true
                severity, message = *@log_tasks.pop
                @logger.add(severity, message)
            end
        end
    end

    def self.get_logfile(params)
        if params["path"] && params["dir"] && params["file"]
            return nil unless File.exist?(params["path"])
            return nil unless File.writable?(params["path"])

            instance_dir = File.basename(params["dir"], '.sqlite')
            log_dir = File.join(params["path"], instance_dir)
            Dir.mkdir(log_dir) unless File.exist?(log_dir)

            log_file = File.basename(params["file"], '.rb') + LOGFILE_EXT
            log_file_path = File.join(log_dir, log_file)

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
            return nil
        end
    end

    def self.group_log(messages)
        @semaphore.synchronize {
            messages.each { |message|
                @log_tasks << message
            }
        }
    end

    def self.unknown(message)
        @log_tasks << [5, message]
    end

    def self.fatal(message)
        @log_tasks << [4, message]
    end

    def self.error(message)
        @log_tasks << [3, message]
    end

    def self.warn(message)
        @log_tasks << [2, message]
    end

    def self.info(message)
        @log_tasks << [1, message]
    end

    def self.debug(message)
        @log_tasks << [0, message]
    end

    def self.close
        sleep(0.1) while @thread.status != 'sleep' && @log_tasks.size > 0
        @thread.terminate
        @logger.close
    end
end
