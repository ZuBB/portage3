#
# Library supporting analytics scripts running on CloudDB
#
# Initial Author: Vasyl Zuzyak, 04/10/12
# Latest Modification: Vasyl Zuzyak, ...
#
require 'logger'

class SimpleLog < Logger::Formatter
    TIME_FORMAT = "%Y-%m-%d %H:%M:%S %z"
    # http://blog.grayproductions.net/articles/the_books_are_wrong_about_logger
    def call(severity, time, program_name, message)
        [
            '[' + time.strftime(TIME_FORMAT) + ']',
            (severity + ':').rjust(6, ' '),
            message
        ].join(" ") + "\n"
    end
end

module PLogger
    @logger = nil
    @log_dir = nil
    @logfile_ext = ".log"

    def self.init(params = {})
        if !params["path"] || !params["dir"] || !params["file"]
            throw "Required parameters was not passed!"
        end

        dir = File.basename(params["dir"])
        dir = dir[0...dir.rindex('.')]
        @log_dir = File.join(params["path"], dir)
        Dir.mkdir(@log_dir) unless File.exist?(@log_dir)

        file = File.basename(params["file"]) + @logfile_ext
        @logger = Logger.new(File.join(@log_dir,  file))
        @logger.level = params["level"] || Logger::DEBUG

        @logger.formatter = SimpleLog.new
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
