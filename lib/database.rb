#
# Library supporting analytics scripts running on CloudDB
#
# Initial Author: Vasyl Zuzyak, 04/05/12
# Latest Modification: Vasyl Zuzyak, ...
#
require 'sqlite3' unless Object.const_defined?(:SQLite3)
 
module Database
    TABLE = "$TN"
    COLUMNS = "$CN"
    VALUES = "$CV"
    INSERT = "$INS"
    
    @database = nil

    def self.init(db_filename)
        unless is_filename_valid?(db_filename)
            throw "Can not create/use db file at `#{db_filename}"
        else
            @database = SQLite3::Database.new(db_filename)
        end
    end

    def self.is_filename_valid?(db_filename)
        return false if db_filename.class != String || db_filename.empty?

        if File.exist?(db_filename)
            filetype = `file -b #{db_filename}`
            return false if filetype.match(/sqlite/i).nil?
            return false unless File.writable?(db_filename)
        else
            return false unless File.writable?(File.dirname(db_filename))
        end

        return true
    end

    def self.prepare()
        @database.transaction()
    end

    def self.create_insert_query(params)
        column_names = []
        values_pattern = []
        sql_query = "#{INSERT} INTO #{TABLE} (#{COLUMNS}) VALUES (#{VALUES});"

        # deal with command
        sql_query.sub!(INSERT, params['command'] || "INSERT")

        # deal with table name
        sql_query.sub!(TABLE, params['table'])

        params["data"].each_key do |key|
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

        params["data"].each_value do |value|
            column_values << value
        end

        return column_values
    end

    def self.insert(params)
        sql_query = params["sql_query"] || create_insert_query(params)
        values = params["values"] || create_insert_values(params)

        begin
            @database.execute(sql_query, *values)
        rescue SQLite3::Exception => exception
            PLogger.error("Database error happened")
            PLogger.error("Message: #{exception.message()}")
            PLogger.error("Sql query: #{sql_query}")
            PLogger.error("Values: [#{values.join(', ')}]")
        end

        return last_inserted_id()
    end

    def self.last_inserted_id()
        return @database.get_first_value("SELECT last_insert_rowid();")
    end

    def self.select(sql_query, values = nil)
        @database.execute(sql_query, *values)
    end

    def self.get_1value(sql_query, values)
        @database.get_first_value(sql_query, *values)
    end

    def self.close()
        @database.commit()
        @database.close() unless @database.closed?
    end

    def self.db()
        @database
    end
end
