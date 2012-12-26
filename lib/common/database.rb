#
# Dumb DB wrapper
#
# Initial Author: Vasyl Zuzyak, 04/05/12
# Latest Modification: Vasyl Zuzyak, ...
#
require 'rubygems'
require 'sqlite3'

class Portage3::Database
    include Portage3::Server

    INSERT = 'insert or ignore into completed_tasks (name) VALUES (?);'
    EXT = 'sqlite'
    EOT = 'DB:EOT'
    EOS = 'DB:EOS'
    PORT = 8119

    def initialize(db_filename)
        @db_filename = db_filename.dup
        @database = SQLite3::Database.new(db_filename)

        # need to set a home dir for logging of this db
        # but we are aware of that dir after db made his vakidation
        dummy_client = Portage3::Logger.class_variable_get('@@dummy_client')
        dummy_client.set_log_dir(db_filename)

        @stats = {}
        @statements = {}
        @completed_tasks = {}
        @semaphore = Mutex.new
        @insert_statement = nil
        @data4db = Queue.new

        # get a log client for db module/object
        @logger = Portage3::Logger.get_client({
            'id'   => Digest::MD5.hexdigest(self.class.name),
            'file' => self.class.name
        })

        start_transaction
        @processing_thread = Thread.new { process_insert_data }
        server = TCPServer.new('localhost', Portage3::Database::PORT)
        loop do
            Thread.start(server.accept) do |connection|
                process_connection(connection)
            end
        end
    end

    def process_insert_data
        while true
            hash = @data4db.pop

            if hash['data'][0] == EOT
                close_statement(hash['id'], hash['data'].last)
                next
            end

            if hash['data'] == [EOS]
                close_database
                break
            end

            begin
                @statements[hash['id']].execute(*hash['data'])
                @stats[hash['id']]['passed'] += 1
            rescue SQLite3::Exception => exception
                @stats[hash['id']]['failed'] += 1
                messages = [
                    "#{'>' * 20} database exception happened #{'>' * 20}",
                    "Message: #{exception.message}",
                    "Values: #{(hash['raw_data'] || hash['data']).inspect}",
                    "#{'<' * 69}"
                ]
                messages.map! { |message| [message, 1, hash['id']] }
                messages[0][1] = Logger::ERROR
                @logger.group_log(messages)
            end
        end
    end

    def validate_query(id, query)
        return false unless query.is_a?(String)
        return false if     query.empty?
        return false unless @database.complete?(query)

        if @insert_statement.nil? && File.size?(@db_filename)
            @insert_statement = @database.prepare(INSERT)
            @logger.info("insert statement has been just created")
        end

        @semaphore.synchronize {
            @stats[id] = { 'passed' => 0, 'failed' => 0 }
            # NOTE here you may get an exception in next case:
            # statement operates on table that is not created yet
            @statements[id] = @database.prepare(query)
            @completed_tasks[id] = Queue.new
        }

        true
    end

    def add_data4insert(item)
        @data4db << item
    end

    def execute(*values)
        @database.execute_batch(*values)
    end

    def safe_execute(*values)
        begin
            @database.execute_batch(*values)
            true
        rescue
            false
        end
    end

    def select(*values)
        @database.execute(*values)
    end

    def get_1value(*values)
        @database.get_first_value(*values)
    end

    def last_inserted_id
        @database.get_first_value("SELECT last_insert_rowid();")
    end

    def close_statement(id, task_name)
        @statements[id].reset!
        @statements[id].close
        @semaphore.synchronize { @statements.delete(id) }
        @logger.info("statement '#{id}' has been closed")

        @insert_statement.execute(task_name)
        @completed_tasks[id] << id
    end

    def get_task_stats(id)
        # to be sure we get all stats, we need to wait till task is completed
        @stats[@completed_tasks[id].pop]
    end

    def start_transaction
        unless @database.transaction_active?
            @logger.info('going to start transaction')
            @database.transaction
        end
    end

    def commit_transaction
        if @database.transaction_active?
            @logger.info('going to commit transaction')
            @database.commit
        end
    end

    def close_database
        @statements.keys.each do |key|
            @statements[key].reset!
            @statements[key].close
            @statements.delete(key)

            @completed_tasks[key] << 0
            @logger.error("Forced to close '#{key}' statement")
        end

        unless @insert_statement.nil?
            @insert_statement.reset!
            @insert_statement.close
        end

        commit_transaction
        @database.close
        @logger.info('closing database')
        @logger.finish_logging
    end

    def self.start_server(db_filename)
        unless self.valid_db_filename?(db_filename)
            throw "Can not create/use db file at `#{db_filename}"
        end

        unless Utils.port_open?(PORT)
            pid = fork { self.new(db_filename) }
            Process.detach(pid)
            # need to wait a bit
            # accessing a server immediately after its start causes error
            sleep(0.2)
            pid
        else
            STDOUT.puts 'previous database server still running'
        end
    end

    def self.valid_db_filename?(db_filename)
        filename_valid = true

        if db_filename.is_a?(String) && !db_filename.empty?
            if File.exist?(db_filename)
                filename_valid &= /#{EXT}/i =~ `file -b #{db_filename}`
                filename_valid &= File.writable?(db_filename)
            else
                filename_valid &= File.writable?(File.dirname(db_filename))
            end
        else
            filename_valid &= false
        end

        filename_valid
    end

    def self.get_client(params = {})
        Portage3::Database::Client.new(params)
    end

    def self.create_db_name
        "portage-cache-#{Utils.get_timestamp}.#{EXT}"
    end
end

class Portage3::Database::Client < Portage3::Client
    def initialize(params = {})
        if params.has_key?('db_filename')
            Portage3::Database.start_server(params['db_filename'])
        end

        super("localhost", Portage3::Database::PORT, params)

        @id_hash = {'id' => @id}

        self
    end

    def set_log_dir(log_dir)
        put('set_log_dir', log_dir)
    end

    def validate_query(query)
        get('validate_query', @id, query)
    end

    def insert(params)
        params = {'data' => params} unless params.is_a?(Hash)
        put('add_data4insert', params.merge(@id_hash))
    end

    def execute(*values)
        put('execute', *values)
    end

    def safe_execute(*values)
        get('safe_execute', *values)
    end

    def select(*values)
        get('select', *values)
    end

    def get_1value(*values)
        get('get_1value', *values)
    end

    def insert_end(task_name)
        insert([Portage3::Database::EOT, task_name])
    end

    # TODO useless?
    def start_transaction
        put('start_transaction')
    end

    def commit_transaction
        put('commit_transaction')
    end

    def get_stats
        get('get_task_stats', @id)
    end

    def shutdown_server
        insert([Portage3::Database::EOS])
    end
end

