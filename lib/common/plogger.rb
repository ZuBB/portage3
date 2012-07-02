#
# Library supporting analytics scripts running on CloudDB
#
# Initial Author: Vasyl Zuzyak, 04/10/12
# Latest Modification: Vasyl Zuzyak, ...
#
require 'logger' unless Object.const_defined?(:Logger)
 
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
    @logfile = nil
    @log4res = nil
    @logfile_ext = ".log"

    def self.init(params = {})
        if params.has_key?("db_filename") && params.has_key?("script")
            unless is_filename_valid?(params["db_filename"])
                throw "Can not find 'anchor' file `#{params["db_filename"]}"
            end

            if params["script"].nil? || params["script"].empty?
                throw "'script' param is not valid"
            end
        end

        if params.has_key?("db_filename") && params.has_key?("script")
            dot_index = params["db_filename"].rindex('.')
            @log_dir = params["db_filename"][0..dot_index - 1]

            Dir.mkdir(@log_dir) unless File.exist?(@log_dir)

            @log4res = params["script"].index('/').nil?() ?
                params["script"] :
                params["script"].split('/').last

            @logfile = File.join(@log_dir,  @log4res + @logfile_ext)
            @logger = Logger.new(@logfile)
            @logger.level = params["level"] || Logger::DEBUG
        else
            @logger = Logger.new(STDOUT)
        end

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
