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
    @sql_queries = []
    @statements = []
    @totals = {}
    @data4db = Queue.new
    @workers_running = true
    @semaphore = Mutex.new
    Thread.abort_on_exception = true
    @thread = Thread.new do
        Thread.current.priority = 1
        Thread.current['passed'] = 0
        Thread.current['failed'] = 0
        Thread.current["name"] = "db worker"

        while (self.is_workers_running? ? true : @data4db.size > 0)
            data2insert = @data4db.pop()

            begin
                # TODO full support of the multiple statements
                @statements[0].execute(*data2insert)
                Thread.current['passed'] += 1
            rescue SQLite3::Exception => exception
                PLogger.group_log([
                    [3, "#{'>' * 20} database exception happened #{'>' * 20}"],
                    [1, "Message: #{exception.message}"],
                    [1, "Values: #{data2insert.inspect}"],
                    [1, "#{'<' * 69}"]
                ])
                Thread.current['failed'] += 1
            end
        end
    end

    def self.init(db_filename, queries = nil)
        filename_valid = true
        if db_filename.is_a?(String) && !db_filename.empty?
            if File.exist?(db_filename)
                filetype = `file -b #{db_filename}`
                filename_valid &= !filetype.match(/sqlite/i).nil?
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

        # TODO merge next if and 'validate_query' function
        if queries
            if queries.is_a?(Array)
                queries.each { |query| self.validate_query(query) }
            elsif queries.is_a?(String)
                self.validate_query(queries)
            else
                throw "Passed sql query is not valid"
            end
        end
    end

    def self.validate_query(query)
        unless @database.complete?(query)
            @database.close
            @sql_queries = nil
            throw "Passed sql query is not valid"
        end
        @sql_queries << query
    end

    def self.add_data4insert(*item)
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

    def self.last_inserted_id()
        @database.get_first_value("SELECT last_insert_rowid();")
    end

    def self.prepare_bunch_insert
        @database.transaction()
        @sql_queries.each { |query|
            @statements << @database.prepare(query)
        }
    end

    def self.is_workers_running?
        @semaphore.synchronize { @workers_running }
    end

    def self.set_workers_done
        @semaphore.synchronize { @workers_running = false }
    end

    def self.finalize_bunch_insert
        sleep(0.1) while @thread.stop? == false

        @thread.terminate
        @database.commit
        @sql_queries = nil
        @statements.each do |statement|
            statement.reset!
            statement.close
        end

        @totals = {
           'passed' => @thread['passed'],
           'failed' => @thread['failed'],
        }
    end

    def self.get_insert_stats
        @totals
    end

    def self.close
        @database.close() unless @database.closed?
    end
end

