#
# Library supporting analytics scripts running on CloudDB
#
# Initial Author: Vasyl Zuzyak, 04/10/12
# Latest Modification: Vasyl Zuzyak, ...
#
require 'optparse' unless Object.const_defined?(:OptionParser)
require 'database' unless Object.const_defined?(:Database)
require 'plogger' unless Object.const_defined?(:PLogger)
require 'utils' unless Object.const_defined?(:Utils)

class Script
    def initialize(params)
        @start_time = nil
        @end_time = nil
        @data = {}

        # merge common options
        @data.merge!(Utils::OPTIONS)
        # merge script options
        @data.merge!(params)
        # get user's options
        @data.merge!(Script.parse_cli_options())
        # TODO
        # #@debug = data["debug"]

        Database.init(@data["db_filename"])
        PLogger.init({
            "db_filename" => @data["db_filename"],
            "script" => @data["script"]
        })
    end

    # TODO: check if all dependant tables are filled
    #File.basename(__FILE__).match(/^\d\d_([a-z]+)\.rb$/)[1].to_s,

    def fill_table_X(fill_table)
        # record time when we start
        @start_time = Time.now
        # open db connection and other related stuff
        Database.prepare()
        # magic.. :)
        fill_table.call(create_walk_params)
        # close db
        Database.close()
        # record time when we finish
        @end_time = Time.now
        # return milliseconds that passed
        return @start_time.to_i - @end_time.to_i
    end

    def create_walk_params()
        result = {
            "method" => @data["method"],
            "portage_home" => File.join(
                @data["portage_home"], @data["home_folder"]
            )
        }

        result["table"] = @data["table"] if @data["table"]
        result["sql_query"] = @data["sql_query"] if @data["sql_query"]
        result["helper_query1"] = @data["helper_query1"] if @data["helper_query1"]
        result["helper_query2"] = @data["helper_query2"] if @data["helper_query2"]

        return result
    end

    # static methods
    def self.parse_cli_options(messages = {})
        options = {}
        OptionParser.new do |opts|
            # help header
            # TODO titles
            opts.banner = " Usage: purge_s3_data [options]\n"
            opts.separator " A script that purges outdated data from s3 bucket\n"

            opts.on("-f", "--database-file STRING",
                    "Path where new database file will be created") do |value|
                # TODO check if path id valid
                options["db_filename"] = value
            end

            # parsing 'quite' option if present
            opts.on("-d", "--debug", "Set log level to 'debug'") do |value|
                options["debug"] = true
            end

            # parsing 'quite' option if present
            opts.on("--log-device STRING", "Your custom log device") do |value|
                options["method"] = value
            end

            # parsing 'quite' option if present
            opts.on("-m", "--method STRING", "Parse method") do |value|
                options["method"] = value
            end

            # parsing 'quite' option if present
            opts.on("-q", "--quiet", "Quiet mode") do |value|
                options["quiet"] = true
            end

            # parsing 'help' option if present
            opts.on_tail("-h", "--help", "Show this message") do
                puts opts
                exit
            end
        end.parse!

        unless options.has_key?("db_filename")
            options["db_filename"] =
                Utils.get_last_created_database(Utils::OPTIONS)
        end

        return options
    end
end
