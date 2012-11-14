#
# Dumb DB wrapper
#
# Initial Author: Vasyl Zuzyak, 04/05/12
# Latest Modification: Vasyl Zuzyak, ...
#
require 'rubygems'
require 'sqlite3'
require 'thread'

module Database
    @database = nil
    @statements = {}
    @data4db = Queue.new
    @semaphore = Mutex.new
    Thread.abort_on_exception = true
    @thread = Thread.new do
        Thread.current.priority = 1
        Thread.current["name"] = "db worker"

        while true
            hash = @data4db.pop

            if hash['data'] == ['DB:EOT']
                self.close_statement(hash['id'])
                next
            end

            break if hash['data'] == ['DB:EOS']

            begin
                @statements[hash['id']].execute(*hash['data'])
                Thread.current[hash['id']]['passed'] += 1
            rescue SQLite3::Exception => exception
                PLogger.group_log(hash['id'], [
                    [3, "#{'>' * 20} database exception happened #{'>' * 20}"],
                    [1, "Message: #{exception.message}"],
                    [1, "Values: #{(hash['raw_data'] || hash['data']).inspect}"],
                    [1, "#{'<' * 69}"]
                ])
                Thread.current[hash['id']]['failed'] += 1
            end
        end
    end

    def self.init(db_filename = '')
        filename_valid = true

        if db_filename.is_a?(String) && !db_filename.empty?
            if File.exist?(db_filename)
                filename_valid &= /sqlite/i =~ `file -b #{db_filename}`
                filename_valid &= File.writable?(db_filename)
            else
                filename_valid &= File.writable?(File.dirname(db_filename))
            end
        else
            filename_valid &= false
        end

        unless filename_valid
            throw "Can not create/use db file at `#{db_filename}"
        end

        @database = SQLite3::Database.new(db_filename)
        @database.transaction
    end

    def self.validate_query(id, query = '')
        result = nil

        if query.is_a?(String) && !query.empty? && @database.complete?(query)
            @semaphore.synchronize {
                # NOTE here you may get an exception in next case:
                # statement operates on table that is not created yet
                @statements[id] = @database.prepare(query)
            }

            @thread[id] = {
                'passed' => 0,
                'failed' => 0
            }

            PLogger.log_info_block(id, query)
            result = true
        else
            result = false
            PLogger.fatal(id, "Passed sql query is not valid")
        end

        result
    end

    def self.add_data4insert(item)
        @data4db << item
    end

    def self.execute(sql_query, *values)
        @database.execute_batch(sql_query, *values)
    end

    def self.select(sql_query, *values)
        @database.execute(sql_query, *values)
    end

    def self.get_1value(sql_query, *values)
        @database.get_first_value(sql_query, *values)
    end

    def self.last_inserted_id
        @database.get_first_value("SELECT last_insert_rowid();")
    end

    def self.end_of_task(id)
        self.add_data4insert({'id' => id, 'data' => ['DB:EOT']})
    end

    def self.close_statement(id)
        @statements[id].reset!
        @statements[id].close
        @semaphore.synchronize { @statements.delete(id) }
    end

    def self.get_stats(id)
        sleep(0.2) while @statements.has_key?(id)
        @thread[id]
    end

    def self.close
        sleep(0.2) while !@statements.empty?
        self.add_data4insert({'data' => ['DB:EOS']})
        @thread.join
        @database.commit
        @database.close unless @database.closed?
    end
end

