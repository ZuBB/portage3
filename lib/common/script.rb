#
# Library supporting analytics scripts running on CloudDB
#
# Filling tables sometimes takes too much time.
# There is nothing bad in doing this in parallel.
# For this I use approach quite similar to 'thread pool' pattern
# http://en.wikipedia.org/wiki/Thread_pool_pattern
# and its Ruby equivalent found on stackoverflow
# http://stackoverflow.com/questions/81788
#
# Initial Author: Vasyl Zuzyak, 04/10/12
# Latest Modification: Vasyl Zuzyak, ...
#
require 'optparse'
require 'database'
require 'plogger'
require 'thread'
require 'utils'

class Script
    def initialize(params)
        @settings = Utils.get_settings()
        @data = {"max_threads" => 2}
        @idle_threads = Queue.new
        @threads = []
        @start_time = nil
        @end_time = nil

        # merge common options
        @data.merge!(Utils::OPTIONS)
        # merge script options
        @data.merge!(params)
        # get user's options
        @data.merge!(Script.get_cli_options())
        if @data["db_filename"].nil?
            @data["db_filename"] = Utils.get_database(@settings)
        end

        # get data for processing
        # #@debug = data["debug"] # TODO

        Database.init(@data["db_filename"], @data["sql_query"])
        PLogger.init({
            "path" => Utils::get_log_home,
            "dir" => @data["db_filename"],
            "file" => $0
        })

        # TODO: check if all dependant tables are filled
        fill_table_X
    end

    def fill_table_X()
        # record time when we start
        @start_time = Time.now
        # open db connection and other related stuff
        data2process = @data["data_source"].call(create_pathes())

        begin
            worker = get_worker()
            worker.set_item(data2process.shift()) unless worker.nil?
        end until data2process.empty?

        # kill all threads
        shutdown()

        # close db
        Database.close()
        # record time when we finish
        @end_time = Time.now
        # return milliseconds that passed
        return @start_time.to_i - @end_time.to_i
    end

    def create_process_params()
        { 'method' => @data['method'] }
    end

    private
    def create_pathes()
        deploy_type = @settings['deploy_type']
        portage_home = @settings['deployments'][deploy_type]['tree_home']
        profiles_home = File.join(portage_home, "profiles")
        new_profiles_home = File.join(portage_home, @settings['new_profiles'])

        {
            'tree_home' => portage_home,
            'profiles2_home' => new_profiles_home,
            # TODO check if it can be removed
            'profiles_home' => profiles_home
        }
    end

    def get_worker()
        if !@idle_threads.empty? or @threads.size == @data["max_threads"]
            #puts 'attemp to get free worker'
            return @idle_threads.pop
        else
            #puts 'have quote: getting new worker'
            worker = Worker.new(
                @idle_threads, @data["thread_code"], create_process_params()
            )
            @threads << worker
            return worker
        end
    end

    def shutdown
        @threads.each { |thread| thread.stop }
        @threads = []
    end

    # static methods
    def self.get_cli_options(messages = {})
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

        return options
    end
end

class Worker
    def initialize(thread_queue, thread_code, params)
        @mutex = Mutex.new
        @cv = ConditionVariable.new
        @idle_threads = thread_queue
        @queue = thread_queue
        @running = true
        @func = thread_code
        Thread.abort_on_exception = true

        @thread = Thread.new do
            @mutex.synchronize do
                while @running
                    @cv.wait(@mutex)
                    item = get_item
                    if item
                        @mutex.unlock
                        @func.call({"value" => item}.merge!(params))
                        @mutex.lock
                        reset_item
                    end
                    @queue << self
                end
            end
        end
    end

    def get_item
        @item
    end

    def set_item(item)
        @mutex.synchronize do
            raise RuntimeError, "Thread already busy." if @item
            @item = item
            @cv.signal
        end
    end

    def stop
        @mutex.synchronize do
            @running = false
            @cv.signal
        end
        @thread.join
    end

    private
    def reset_item
        @item = nil
    end
end

