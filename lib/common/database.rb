#
# Library supporting analytics scripts running on CloudDB
#
# Initial Author: Vasyl Zuzyak, 04/05/12
# Latest Modification: Vasyl Zuzyak, ...
#
require 'rubygems'
require 'sqlite3'
require 'thread'
 
module Database
    TABLE = "$TN"
    COLUMNS = "$CN"
    VALUES = "$CV"
    INSERT = "$INS"
    
    @database = nil
    @statement = nil
    @queue = Queue.new
    @mutex = Mutex.new
    @resource = ConditionVariable.new
    Thread.abort_on_exception = true
    @running = true
    @data = nil
    @thread = Thread.new do
        @mutex.synchronize do
            while @running
            #p 'in thread; before WAIT'
                @resource.wait(@mutex)
            #p 'in thread; after WAIT'
                next if @data.nil?

                #@mutex.unlock
                last_id_case = nil
                select_case = nil
                result_set = nil

                begin
                    command = @data["sql_query"].downcase.split(' ')[0]
                    last_id_case = ['insert', 'update'].include?(command)
                    select_case = command == 'select'

                    unless @statement.nil?
                        if !@data["values"].nil?
                            @statement.bind_params(*@data["values"])
                        end
                        result_set = @statement.execute()
                    else
                        result_set = @database.execute2(
                            @data["sql_query"], *@data["values"]
                        )
                    end
                rescue SQLite3::Exception => exception
                    PLogger.error("Database error happened")
                    PLogger.error("Message: #{exception.message()}")
                    PLogger.error("Sql query: #{@data["sql_query"]}")
                    unless @data["values"].nil?
                        PLogger.error("Values: [#{@data["values"].join(', ')}]")
                    end
                end

                #@mutex.lock
                #@data["result"] = last_inserted_id() if last_id_case
                @data["result"] = result_set.drop(1) if select_case
                #@data["result"] = nil if last_inserted_id.nil? && select_case.nil?
            end
        end
    end
    @queue << @thread

    def self.init(db_filename)
        unless is_filename_valid?(db_filename)
            throw "Can not create/use db file at `#{db_filename}"
        else
            @database = SQLite3::Database.new(db_filename)
            @database.transaction()
        end
    end

    def self.is_filename_valid?(db_filename)
        return false if !db_filename.is_a?(String) || db_filename.empty?

        if File.exist?(db_filename)
            filetype = `file -b #{db_filename}`
            return false if filetype.match(/sqlite/i).nil?
            return false unless File.writable?(db_filename)
        else
            return false unless File.writable?(File.dirname(db_filename))
        end

        return true
    end

    def self.create_insert_query(params)
        column_names = []
        values_pattern = []
        sql_query = "#{INSERT} INTO #{TABLE} (#{COLUMNS}) VALUES (#{VALUES});"

        # deal with command
        sql_query.sub!(INSERT, params['command'] || "INSERT")

        # deal with table name
        sql_query.sub!(TABLE, params['table'])

        params["data"].keys.sort.each do |key|
            column_names << key
            values_pattern << '?'
        end

        # deal with column names
        sql_query.sub!(COLUMNS, column_names.join(', '))
        # deal with column values
        sql_query.sub!(VALUES, values_pattern.join(', '))

        return sql_query
    end

    def self.create_insert_values(params)
        column_values = []

        params["data"].keys.sort.each do |key|
            column_values << params["data"][key]
        end

        return column_values
    end

    def self.insert2(params)
        #p '--- START'
        #p 'in insert2'
        sql_query = params["sql_query"] || create_insert_query(params)
        values = params["values"] || create_insert_values(params)

        if @statement.nil?
            @statement = @database.prepare(sql_query)
        end

        @queue.pop()
        #p 'in insert2; got free thread'
        self.set_data(sql_query, values)
        self.reset_data()
    end

    def self.insert(params)
        @queue.pop()
        self.set_data(
            params["sql_query"] || create_insert_query(params),
            params["values"] || create_insert_values(params)
        )
        self.reset_data()
    end

    def self.execute(sql_query, values = nil)
        @queue.pop()
        self.set_data(sql_query, values)
        self.reset_data()
    end

    def self.select(sql_query, values = nil)
        @queue.pop()
        self.set_data(sql_query, values)
        self.reset_data()
    end

    def self.get_1value(sql_query, values = nil)
        # TODO get *params in call.
        # unshift sql
        # use else as values
        values = [values] unless values.is_a?(Array)
        @database.get_first_value(sql_query, *values)
    end

    def self.last_inserted_id()
        return @database.get_first_value("SELECT last_insert_rowid();")
    end

    def self.set_data(sql_query, values = nil)
        #p 'in set_data'
        @mutex.synchronize do
            raise RuntimeError, "Thread already busy." unless @data.nil?
            @data = {
                "sql_query" => sql_query,
                "values" => values.nil?() ? [] : [values].flatten,
            }
            # Signal the thread in this class, that there's a job to be done
            #p 'in set_data; before SIGNAL'
            @resource.signal
        end
    end

    def self.reset_data()
        #p 'in reset_data; waiting for thread'
        # lets waint until thread finish
        while @thread.status != 'sleep'
            sleep(0.02)
        end
        #p 'in reset_data; thread should sleep'

        result = nil
        @mutex.synchronize do
            # something made thread running
            if @thread.status != 'sleep'
                raise RuntimeError, "Thread already gone."
            end
            #p 'in reset_data; thread sleeps INDEED'

            # something cleared data
            if @thread.status == 'sleep' && @data.nil?
                raise RuntimeError, "Data already gone."
            end
            #p 'in reset_data; RESET'

            # get result and add thread to the queue
            result = @data.delete('result')
            @data = nil
            #p '--- BEFORE END'
            @queue << @thread
        end
        result
    end

    def self.close()
        @statement.close if @statement.is_a?(SQLite3::Statement)
        @mutex.synchronize do
            @running = false
            @resource.signal
        end
        @thread.join
        @database.commit()
        @database.close() unless @database.closed?
    end
end
