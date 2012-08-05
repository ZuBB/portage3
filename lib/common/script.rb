#
# Class for
#   * parallel processing income data
#   * passing processed data to the DB queue
#
# Filling tables sometimes takes too much time.
# There is nothing bad in doing this in parallel.
# For this I use approach quite similar to 'thread pool' pattern
# http://en.wikipedia.org/wiki/Thread_pool_pattern
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
        @shared_data = {}
        @jobs = Queue.new
        @pool = nil
        @data = {}

        get_script_options(params)

        Database.init(@data['db_filename'], @data['sql_query'])

        PLogger.init({
            'level' => @data["debug"] ? Logger::DEBUG : Logger::INFO,
            'path' => Utils::get_log_home,
            'dir' => @data['db_filename'],
            'file' => $0
        })

        log_sql_queries
        fill_table_X
    end

    def fill_table_X()
        stats = { 'start_time' => Time.now }

        get_data()
        stats['total'] = @jobs.size
        pre_insert_task if defined?(pre_insert_task) == 'method'
        @shared_data.freeze

        Database.prepare_bunch_insert
        run_workers
        Database.set_workers_done
        Database.finalize_bunch_insert

        if defined?(post_insert_check) == 'method'
            post_insert_check if @data['run_check']
        end

        stats['end_time'] = Time.now
        stats.merge!(Database.get_insert_stats)

        handle_stats(stats)

        Database.close
        PLogger.close
    end

    private
    def get_script_options(params)
        # TODO find best value for 'max_threads'
        @data = {"max_threads" => File.basename($0).start_with?('3') ? 4 : 2}
        @data.merge!(Utils::OPTIONS)
        @data.merge!(params)
        @data.merge!(Script.get_cli_options())
    end

    def get_data()
        if [Method, Proc].include?(@data["data_source"].class)
            result = @data["data_source"].call(Utils.get_pathes)
            result.each { |item| @jobs << item } if result.is_a?(Array)
            result = nil
        else
            throw 'No data passed'
        end
    end

    def run_workers()
        Thread.abort_on_exception = true

        @pool = Array.new(@data['max_threads']) do |i|
            Thread.new do
                Thread.current["name"] = "worker ##{i}"
                Thread.current['count'] = 0

                while @jobs.size > 0 do
                    data2insert = @jobs.pop
                    if defined?(process) == 'method'
                        process(data2insert)
                    else
                        Database.add_data4insert(data2insert)
                    end
                    Thread.current['count'] += 1
                end
            end
        end

        @pool.each { |thread| thread.join }
    end

    def log_sql_queries
        PLogger.info('Passed queries:')
        [@data['sql_query']].flatten.each  { |sql_query|
            PLogger.info("#{'-' * 70}")
            PLogger.info(sql_query)
        }
        PLogger.info("#{'-' * 70}")
    end

    def handle_stats(results)
        if defined?(custom_stats_handler) == 'method'
            custom_stats_handler(results)
        else
            elaped = results['end_time'] - results['start_time']
            PLogger.group_log([
                [1, "#{'=' * 35} SUMMARY #{'=' * 35}"],
                [1, "Time elapsed: #{elaped} seconds"],
                [1, "Total amount of jobs for processing: #{results['total']}"],
                [1, "Successful inserts: #{results['passed']}"],
                [1, "Faileddddd inserts: #{results['failed']}"]
            ])
        end
    end

    def self.get_cli_options(messages = {})
        options = {}
        OptionParser.new do |opts|
            # TODO set titles using passed 'messages' Hasj
            opts.banner = " Usage: purge_s3_data [options]\n"
            opts.separator " A script that purges outdated data from s3 bucket\n"

            opts.on("-f", "--database-file STRING",
                    "Path where new database file will be created") do |value|
                options["db_filename"] = value
            end

            opts.on("-d", "--debug", "Set log level to 'debug'") do |value|
                options["debug"] = true
            end

            opts.on("--log-device STRING", "Your custom log device") do |value|
                options["method"] = value
            end

            opts.on("-m", "--method STRING", "Parse method") do |value|
                options["method"] = value
            end

            opts.on("-q", "--quiet", "Quiet mode") do |value|
                options["quiet"] = true
            end

            opts.on_tail("-h", "--help", "Show this message") do
                puts opts
                exit
            end
        end.parse!

        options["db_filename"] ||= Utils.get_database()
        options
    end
end

