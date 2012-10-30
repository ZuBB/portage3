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
require 'digest/md5'

class Tasks::Runner
    def initialize(params)
        @id          = get_task_id(params['name'])
        @jobs        = Queue.new
        @stats       = {'timings' => []}
        @insert_stub = {'id' => @id}

        # init log device
        # TODO custom log device?
        PLogger.init_device({'file' => params['name'], 'id' => @id})

        # validate and register 'INSERT' query
        if Database.validate_query(@id, self.class::SQL['insert'])
            process_task_methods
        end

        log_stats(params['start'])
        PLogger.end_of_task(@id)
    end

    def process_task_methods
        process_get_data_method
        process_get_shared_data_method
        process_pre_insert_method

        fill_table

        process_post_insert_check_method
        process_post_insert_method

        Database.end_of_task(@id)
        @stats.merge!(Database.get_stats(@id))
    end

    def process_get_data_method
        start_time = Time.now

        if defined?(get_data) == 'method'
            get_data(Utils.get_pathes).each { |item| @jobs << item }
            @stats['total'] = @jobs.size
            store_timeframe(__method__, start_time, Time.now)
        end
    end

    def process_get_shared_data_method
        start_time = Time.now

        if defined?(get_shared_data) == 'method'
            get_shared_data
            store_timeframe(__method__, start_time, Time.now)
        end
    end

    def process_pre_insert_method
        start_time = Time.now

        if defined?(pre_insert) == 'method'
            #pre_insert
            store_timeframe(__method__, start_time, Time.now)
        end
    end

    def fill_table
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
                        send_data4insert({'data' => item2process})
                    end
                    Thread.current['count'] += 1
                end
            end
        end

        pool.each { |thread| thread.join }
        pool.each { |thread| @stats[thread['name']] = thread['count'] }

        store_timeframe(__method__, start_time, Time.now)
    end

    def process_post_insert_check_method
        start_time = Time.now

        if defined?(post_insert_check) == 'method'
            if @data['run_check']
                #PLogger.info("#{'=' * 35} CHECKS #{'=' * 35}")
                #post_insert_check
                store_timeframe(__method__, start_time, Time.now)
            end
        end
    end

    def process_post_insert_method
        start_time = Time.now

        if defined?(post_insert_task) == 'method'
            PLogger.info("#{'=' * 30} post_insert_task #{'=' * 30}")
            message = post_insert_task
            PLogger.info(message) unless message.nil?
            store_timeframe(__method__, start_time, Time.now)
        end
    end

    def log_stats(start_time)
        logs = [["#{'=' * 35} SUMMARY #{'=' * 35}"]]
        store_timeframe("Total time", start_time, Time.now)

        @stats['timings'].each { |hash|
            method_name = hash.keys.first
            timeframe = hash.values.first
            logs << ["#{method_name}: elapsed #{timeframe} milliseconds"]
        }

        logs << ["Total amount of items for processing: #{@stats['total']}"]

        @stats.keys
        .select { |key| key.start_with?('worker') }
        .each { |key| logs << ["Thread '#{key}' processed #{@stats[key]} items"] }

        PLogger.group_log(@id, logs.each { |log| log.insert(0, 1) })
        PLogger.group_log(@id, [
            [1, "Successful inserts: #{@stats['passed']}"],
            [1, "Faileddddd inserts: #{@stats['failed']}"]
        ])
    end

    # {
    #     'id'       => @id,
    #     'data'     => item2process,
    #     'raw_data' => item2process
    # }
    def send_data4insert(data)
        Database.add_data4insert(data.merge(@insert_stub))
    end

    def store_timeframe(method_name, start_time, end_time)
        @stats['timings'] << {
            method_name => ((end_time - start_time) * 1000.0).to_i
        }
    end

    def get_task_id(class_name)
        id = []

        id << class_name
        id << self.class::DEPENDS rescue ''
        id << self.class::PROVIDES rescue ''
        id << self.class::SQL['insert'] rescue ''

        Digest::MD5.hexdigest(id.join)
    end

    def shared_data(data_key, item_key)
        Tasks::Scheduler.class_variable_get(:@@shared_data)[data_key][item_key]
    end
end

