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

        @jobs        = Queue.new
        @id          = self.class.get_task_id
        @stats       = {'timings' => []}
        @logger      = get_logger_client(params)
        @database    = get_database_client

        @logger.info(@id)
        @logger.log_info_block(self.class::SQL['insert'])

        if @database.validate_query(self.class::SQL['insert'])
            process_task_methods(params['name'])
        else
            @logger.fatal("Passed sql query is not valid")
        end

        log_stats(start_time)
        @logger.finish_logging
    end

    def process_task_methods(class_name)
        process_get_data_method
        process_set_shared_data_method

        process_pre_fill_method
        fill_table
        process_post_fill_method

        send_end_mark(class_name)
        wait_4_end_confirmation
        store_db_stats
    end

    def process_get_data_method
        start_time = Time.now

        if defined?(get_data) == 'method'
            get_data(Utils.get_pathes).each { |item| @jobs << item }
            @stats['total'] = @jobs.size
            store_timeframe(__method__, start_time, Time.now)
        else
            @logger.warn('`get_data` method is not defined')
        end
    end

    def process_set_shared_data_method
        start_time = Time.now

        if defined?(set_shared_data) == 'method'
            @logger.info("found 'get_shared_data' method, executing")
            set_shared_data
            store_timeframe(__method__, start_time, Time.now)
        end
    end

    def process_pre_fill_method
        start_time = Time.now

        if defined?(pre_insert) == 'method'
            @logger.info("found 'pre_insert' method, executing")
            #pre_insert
            store_timeframe(__method__, start_time, Time.now)
        end
    end

    def fill_table_old
        start_time = Time.now

        threads = self.class::THREADS rescue 1
        Thread.abort_on_exception = true

        pool = Array.new(threads) do |i|
            Thread.new do
                Thread.current["name"] = "worker ##{i + 1}"
                Thread.current['count'] = 0

                while @jobs.size > 0 do
                    item2process = @jobs.pop
                    if defined?(process_item) == 'method'
                        process_item(item2process)
                    else
                        send_data4insert(item2process)
                    end
                    Thread.current['count'] += 1
                end
            end
        end

        pool.each { |thread| thread.join }
        pool.each { |thread| @stats[thread['name']] = thread['count'] }

        store_timeframe(__method__, start_time, Time.now)
    end

    def fill_table
        start_time = Time.now

        while @jobs.size > 0 do
            item2process = @jobs.pop
            if defined?(process_item) == 'method'
                process_item(item2process)
            else
                send_data4insert(item2process)
            end
        end

        store_timeframe(__method__, start_time, Time.now)
    end

    def process_post_fill_method
        start_time = Time.now

        if defined?(post_insert_task) == 'method'
            @logger.info("found 'post_insert_task' method, executing")
            #message = post_insert_task
            #PLogger.info(message) unless message.nil?
            store_timeframe(__method__, start_time, Time.now)
        end
    end

    def send_end_mark(class_name)
        start_time = Time.now
        @database.insert_end(class_name)
        store_timeframe(__method__, start_time, Time.now)
    end

    def wait_4_end_confirmation
        start_time = Time.now
        @database.wait_4_end_confirmation
        store_timeframe(__method__, start_time, Time.now)
    end

    def store_db_stats
        start_time = Time.now

        db_stats = @database.get_stats

        if self.class::SQL.has_key?('amount')
            db_stats['passed'] = @database.get_1value(
                self.class::SQL['amount'],
                shared_data('source@id', self.class::SOURCE)
            )
        end

        params   = ['db_insert']
        params  << db_stats.delete('start_time')
        params  << db_stats.delete('end_time')
        store_timeframe(*params)

        @stats.merge!(db_stats)
        store_timeframe(__method__, start_time, Time.now)
    end

    def log_stats(start_time)
        logs = [
            "#{'=' * 20} SUMMARY #{'=' * 20}",
            "Total amount of items for processing: #{@stats['total']}"
        ]
        store_timeframe("Total time", start_time, Time.now)

        @stats['timings'].each { |hash|
            method_name = hash.keys.first
            timeframe = hash.values.first
            logs << "#{method_name}: elapsed #{timeframe} milliseconds"
        }

        @stats.keys
        .select { |key| key.start_with?('worker') }
        .each { |key| logs << "Thread '#{key}' processed #{@stats[key]} items" }

        logs << "Successful inserts: #{@stats['passed']}"
        logs << "Faileddddd inserts: #{@stats['failed']}"

        @logger.group_log(logs)
    end

    # {
    #     'id'       => @id,
    #     'data'     => item2process,
    #     'raw_data' => item2process
    # }
    def send_data4insert(data)
        @database.insert(data)
    end

    def store_timeframe(method_name, start_time, end_time)
        @stats['timings'] << {
            method_name => ((end_time - start_time) * 1000.0).to_i
        }
    end

    def request_data(key, sql_query, force = false)
        Tasks::Scheduler.set_shared_data(key, sql_query, force)
    end

    def shared_data(data_key, item_key)
        shared_data = Tasks::Scheduler.class_variable_get('@@shared_data')

        unless shared_data.has_key?(data_key)
            @logger.error("shared data does not have '#{data_key}' object")
            return nil
        end

        unless shared_data[data_key].has_key?(item_key)
            message = "object '#{data_key}' of shared data does not have"\
                " '#{item_key}' value"
            # TODO what to do with this?
            #@logger.warn(message)
            return nil
        end

        shared_data[data_key][item_key]
    end

    def get_logger_client(params)
        Portage3::Logger.get_client({
            'debug' => params['log_level'],
            'file'  => params['name'],
            'id'    => @id
        })
    end

    def get_database_client
        Portage3::Database.get_client({'id' => @id})
    end

    def self.get_task_id
        Digest::MD5.hexdigest([
            self.name.to_s,
            self::SQL['insert'],
            (self::DEPENDS rescue '')
        ].join('|'))
    end
end
