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

class Tasks::Runner
    def initialize(params)
        start_time = Time.now

        @shared_data = {}
        @jobs        = nil
        @id          = self.class.get_task_id
        @stats       = {'timings' => []}
        @logger      = get_logger(params)
        @database    = Portage3::Database::Client.new

        @logger.info(@id)
        @logger.log_block([self.class::SQL['insert']])

        result = @database.get({
            'action' => 'get_validate_query',
            'params' => [@id, self.class::SQL['insert']]
        })

        if result
            @logger.info("SQL query is valid")
            process_task_methods(params['name'])
        else
            @logger.fatal("Passed sql query is not valid")
        end

        log_stats(start_time)
        @logger.close
    end

    def process_task_methods(class_name)
        process_get_data_method
        process_get_shared_data_method
        process_pre_insert_method

        fill_table

        process_post_insert_check_method
        process_post_insert_method

        end_db_stuff(class_name)
    end

    def process_get_data_method
        start_time = Time.now

        if defined?(get_data) == 'method'
            @logger.info("found 'get_data' method, executin")
            @jobs = get_data(Utils.get_pathes)
            @stats['total'] = @jobs.size
            store_timeframe(__method__, start_time, Time.now)
        end
    end

    def process_get_shared_data_method
        start_time = Time.now

        if defined?(get_shared_data) == 'method'
            @logger.info("found 'get_shared_data' method, executin")
            @cached = Tasks::Scheduler.create_client_socket
            get_shared_data
            @cached.close
            store_timeframe(__method__, start_time, Time.now)
        end
    end

    def process_pre_insert_method
        start_time = Time.now

        if defined?(pre_insert) == 'method'
            @logger.info("found 'pre_insert' method, executin")
            #pre_insert
            store_timeframe(__method__, start_time, Time.now)
        end
    end

    def fill_table
        start_time = Time.now

        while @jobs.size > 0 do
            item2process = @jobs.shift
            if defined?(process_item) == 'method'
                process_item(item2process)
            else
                send_data4insert({'data' => item2process})
            end
        end

        store_timeframe(__method__, start_time, Time.now)
    end

    def process_post_insert_check_method
        start_time = Time.now

        if defined?(post_insert_check) == 'method'
            if @data['run_check']
                @logger.info("found 'post_insert_check' method, executin")
                #post_insert_check
                store_timeframe(__method__, start_time, Time.now)
            end
        end
    end

    def process_post_insert_method
        start_time = Time.now

        if defined?(post_insert_task) == 'method'
            @logger.info("found 'post_insert_task' method, executin")
            #message = post_insert_task
            #PLogger.info(message) unless message.nil?
            store_timeframe(__method__, start_time, Time.now)
        end
    end

    def end_db_stuff(class_name)
        start_time = Time.now
        send_data4insert({'data' => [Portage3::Database::EOT, class_name]})
        @stats.merge!(@database.get_and_close({
            'action' => 'get_task_stats',
            'params' => @id
        }))
        store_timeframe(__method__, start_time, Time.now)
    end

    def log_stats(start_time)
        logs = [
            "#{'=' * 35} SUMMARY #{'=' * 35}",
            "Total amount of items for processing: #{@stats['total']}"
        ]
        store_timeframe("Total time", start_time, Time.now)

        @stats['timings'].each { |hash|
            method_name = hash.keys.first
            timeframe = hash.values.first
            logs << "#{method_name}: elapsed #{timeframe} milliseconds"
        }

        logs << "Successful inserts: #{@stats['passed']}"
        logs << "Faileddddd inserts: #{@stats['failed']}"

        @logger.log_group(logs)
    end

    # {
    #     'id'       => @id,
    #     'data'     => item2process,
    #     'raw_data' => item2process
    # }
    def send_data4insert(data)
        @database.put({
            'action' => 'add_data4insert',
            'params' => [data.merge!({'id' => @id})]
        })
    end

    def store_timeframe(method_name, start_time, end_time)
        @stats['timings'] << {
            method_name => ((end_time - start_time) * 1000.0).to_i
        }
    end

    def set_shared_data(key, sql_query)
        @cached.puts(JSON.generate({'key' => key, 'query' => sql_query}))
        @shared_data[key] = JSON.parse(@cached.gets)['result']
    end
    
    def shared_data(data_key, item_key)
        unless @shared_data.has_key?(data_key)
            @logger.error("shared data does not have '#{data_key}' object")
        end

        unless @shared_data[data_key].has_key?(item_key)
            message = "object '#{data_key}' of shared data does not have"\
                "'#{item_key}' value"
            @logger.error(message)
        end

        @shared_data[data_key][item_key]
    end

    def get_logger(params)
        Portage3::Logger::Client.new({
            'id'      => @id,
            'file'    => params['name'],
            'debug'   => params['log_level'],
            'log_dir' => params['db_filename']
        })
    end

    def self.get_task_id
        id = []

        id << self.name.to_s
        id << self::DEPENDS rescue ''
        id << self::SQL['insert']

        Digest::MD5.hexdigest(id.join('|'))
    end
end

