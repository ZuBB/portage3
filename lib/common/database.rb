#
# Dumb DB wrapper
#
# Initial Author: Vasyl Zuzyak, 04/05/12
# Latest Modification: Vasyl Zuzyak, ...
#

require 'rubygems'
require 'sqlite3'

module Portage3::Database
    PORT = 8119
    EOT = 'DB:EOT'
    EOS = 'DB:EOS'
    EXT = 'sqlite'

    def self.start_server(db_filename)
        unless Portage3::Database.validate_db_filename(db_filename)
            throw "Can not create/use db file at `#{db_filename}"
        end

        unless Utils.port_open?(PORT)
            pid = fork { Portage3::Database::Server.new(db_filename) }
            Process.detach(pid)
            # need to wait a bit
            # accessing a server immediately after its start causes error
            sleep(0.2)
            pid
        else
            STDOUT.puts 'previous database server still running'
        end
    end

    def self.validate_db_filename(db_filename)
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

    def self.create_db_name
        "portage-cache-#{Utils.get_timestamp}.#{EXT}"
    end
end

class Portage3::Database::Server
    INSERT = 'insert or ignore into completed_tasks (name) VALUES (?);'

    def initialize(db_filename)
        @database = SQLite3::Database.new(db_filename)
        @db_filename = db_filename.dup

        @stats = {}
        @statements = {}
        @completed_tasks = {}
        @insert_statement = nil
        @data4db = Queue.new

        @logger = Portage3::Logger::Client.new({
            'log_dir' => db_filename,
            'file'    => self.class.name,
            'id'      => Digest::MD5.hexdigest(self.class.name)
        })

        @logger.info('lets start')
        start_transaction
        Thread::abort_on_exception = true
        @insert_thread = Thread.new { process_insert_data }
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

            if hash['data'].is_a?(Array) && hash['data'].first == Portage3::Database::EOT
                close_statement(hash['id'], hash['data'].last)
                next
            end

            if hash['data'] == Portage3::Database::EOS
                close_database
                break
            end

            begin
                @statements[hash['id']].execute(*hash['data'])
                @stats[hash['id']]['passed'] += 1
            rescue SQLite3::Exception => exception
                @stats[hash['id']]['failed'] += 1
                messages = [
                    ["#{'>' * 20} database exception happened #{'>' * 20}"],
                    ["Message: #{exception.message}"],
                    ["Values: #{(hash['raw_data'] || hash['data']).inspect}"],
                    ["#{'<' * 69}"]
                ]
                messages.each { |m| m.concat([1, hash['id']]) }
                messages[0][1] = Logger::ERROR
                @logger.log_group(messages)
            end
        end
    end

    def process_connection(connection)
        connection.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1)
        while accepted_string = connection.gets
            begin
                json_object = JSON.parse(accepted_string)
            rescue
                @logger.error('Failed to parse next incoming string')
                @logger.info(accepted_string)
                next
            end

            unless json_object.has_key?('action')
                @logger.warn('incoming object does not have \'action\' param')
                next
            end

            result = send(json_object['action'], *json_object['params'])

            if json_object['action'].start_with?('get_')
                connection.puts(JSON.generate({'result' => result}))
            end

            if (json_object['params'][0]['data'] rescue false) == Portage3::Database::EOS
                @insert_thread.join
                connection.close
                Process.exit(true)
            end
        end
    end

    def get_validate_query(id, query)
        return false unless query.is_a?(String)
        return false if     query.empty?
        return false unless @database.complete?(query)

        # NOTE here you may get an exception in next case:
        # statement operates on table that is not created yet
        @statements[id] = @database.prepare(query)

        @completed_tasks[id] = Queue.new
        @stats[id] = {
            'passed' => 0,
            'failed' => 0
        }

        true
    end

    def create_insert_statement
        if @insert_statement.nil? && File.size?(@db_filename)
            @insert_statement = @database.prepare(INSERT)
        end
    end

    def add_data4insert(item)
        @data4db << item
    end

    def execute(*values)
        @database.execute_batch(*values)
    end

    def get_safe_execute(*values)
        begin
            @database.execute_batch(*values)
            true
        rescue
            false
        end
    end

    def get_select(*values)
        @database.execute(*values)
    end

    def get_1value(*values)
        @database.get_first_value(*values)
    end

    def get_last_inserted_id
        @database.get_first_value("SELECT last_insert_rowid();")
    end

    def start_transaction
        @database.transaction unless @database.transaction_active?
    end

    def commit_transaction
        @database.commit if @database.transaction_active?
    end

    def close_statement(id, task_name)
        @completed_tasks[id] << id
        @insert_statement.execute(task_name)
        @statements[id].reset!
        @statements[id].close
        @statements.delete(id)
    end

    def get_task_stats(id)
        # to be sure we get all stats, we need to wait till task is completed
        @stats[@completed_tasks[id].pop]
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

        @logger.info('closing database')
        @database.commit
        @database.close

        @logger.info('just before exit')
        @logger.close
    end
end

class Portage3::Database::Client < Portage3::Client
    def initialize(db_filename = '')
        if db_filename.size > 0
            Portage3::Database.start_server(db_filename)
        end

        super("localhost", Portage3::Database::PORT)

        start_transaction
        create_insert_statement

        self
    end

    def start_transaction
        put({'action' => 'start_transaction'})
    end

    def create_insert_statement
        put({'action' => 'create_insert_statement'})
    end
end

