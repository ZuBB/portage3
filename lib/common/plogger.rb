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
        TIME_FORMAT = "%Y-%m-%d %H:%M:%S %z"
        def call(severity, time, program_name, message)
            [
                '[' + time.strftime(TIME_FORMAT) + ']',
                (severity + ':').rjust(6, ' '),
                message
            ].join(" ") + "\n"
        end
    end

    LOGFILE_EXT = ".log"
    @log_file = nil
    @logger = nil

    def self.init(params = {})
        if (@log_file = self.get_logfile(params)).nil?
            throw "Required parameters was not passed!"
        end

        @logger = Logger.new(@log_file)
        @logger.level = params["level"] || Logger::DEBUG
        @logger.formatter = SimpleLog.new
    end

    def self.get_logfile(params)
        if params["path"] && params["dir"] && params["file"]
            return nil unless File.exist?(params["path"])
            return nil unless File.writable?(params["path"])

            instance_dir = File.basename(params["dir"], '.sqlite')
            log_dir = File.join(params["path"], instance_dir)
            Dir.mkdir(log_dir) unless File.exist?(log_dir)

            log_file = File.basename(params["file"], '.rb') + LOGFILE_EXT
            return File.join(log_dir, log_file)
        elsif params['logfile']
            dir = File.dirname(params['logfile'])

            return nil unless File.exist?(dir)
            return nil unless File.writable?(dir)

            return params['logfile']
        else
            return nil
        end
    end

    def self.is_filename_valid?(db_filename)
        if db_filename.class != String || db_filename.empty?
            return false
        else
            return File.exist?(db_filename)
        end
    end

    def self.fatal(message)
        @logger.fatal(message) unless message.nil? && message.empty?
    end

    def self.error(message)
        @logger.error(message) unless message.nil? && message.empty?
    end

    def self.warn(message)
        @logger.warn(message) unless message.nil? && message.empty?
    end

    def self.info(message)
        @logger.info(message) unless message.nil? && message.empty?
    end

    def self.debug(message)
        @logger.debug(message) unless message.nil? && message.empty?
    end

    def self.__log(severity, message)
        # TODO?
        unless message.nil? && message.empty?
            #@logger.add(severity, message)
        end
    end
end
