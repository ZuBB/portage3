#
# Dumb DB wrapper
#
# Initial Author: Vasyl Zuzyak, 04/05/12
# Latest Modification: Vasyl Zuzyak, ...
#
require 'rubygems'
require 'sqlite3'

module Portage3::Database
    INSERT = 'insert or ignore into completed_tasks (name) VALUES (?);'
    EXT = 'sqlite'

    @@stats = {'db_inserts' => 0}
    @@completed_tasks = {}
    @@insert_statement = nil
    @@database = nil
    @@statements = {}
    @@data4db = Queue.new
    @@semaphore = Mutex.new
    @@thread = Thread.new do
        Thread.current.priority = 1
        Thread.current["name"] = "db worker"

        while true
            hash = @@data4db.pop

            if hash['data'][0] == 'DB:EOT'
                self.close_statement(hash['id'], hash['data'].last)
                next
            end

            if hash['data'] == ['DB:EOS']
                close_database
                break
            end

            begin
                @@statements[hash['id']].execute(*hash['data'])
                @@stats[hash['id']]['passed'] += 1
                @@stats['db_inserts'] += 1
            rescue SQLite3::Exception => exception
                @@stats[hash['id']]['failed'] += 1
                messages = [
                    "#{'>' * 20} database exception happened #{'>' * 20}",
                    "Message: #{exception.message}",
                    "Values: #{(hash['raw_data'] || hash['data']).inspect}",
                    "#{'<' * 69}"
                ]
                messages.map! { |message| [message, 1, hash['id']] }
                messages[0][1] = Logger::ERROR
                @@logger.group_log(messages)
            end
        end
    end

    def self.init(db_filename)
        unless self.valid_db_filename?(db_filename)
            throw "Can not create/use db file at `#{db_filename}"
        end

        @@db_filename = db_filename.dup
        @@database = SQLite3::Database.new(db_filename)

        # need to set a home dir for logging of this db
        # but we are aware of that dir after db made his vakidation
        dummy_client = Portage3::Logger.class_variable_get('@@dummy_client')
        dummy_client.set_log_dir(db_filename)

        # get a log client for db module/object
        @@logger = Portage3::Logger.get_client({
            'id'   => Digest::MD5.hexdigest(self.name),
            'file' => self.name
        })

        @@logger.info('lets start')
        self.start_transaction
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

    def self.validate_query(id, query)
        return false unless query.is_a?(String)
        return false if     query.empty?
        return false unless @@database.complete?(query)

        if @@insert_statement.nil? && File.size?(@@db_filename)
            @@insert_statement = @@database.prepare(INSERT)
            @@logger.info("insert statement has been just created")
        end

        self.start_transaction

        @@semaphore.synchronize {
            # NOTE here you may get an exception in next case:
            # statement operates on table that is not created yet
            @@statements[id] = @@database.prepare(query)
            @@completed_tasks[id] = Queue.new
            @@stats[id] = {
                'start_time' => Time.now,
                'end_time'   => nil,
                'passed'     => 0,
                'failed'     => 0
            }
        }

        true
    end

    def self.add_data4insert(item)
        @@data4db << item
    end

    def self.execute(sql_query, *values)
        @@database.execute_batch(sql_query, *values)
    end

    def self.safe_execute(*values)
        begin
            @@database.execute_batch(*values)
            true
        rescue
            false
        end
    end

    def self.select(sql_query, *values)
        @@database.execute(sql_query, *values)
    end

    def self.get_1value(sql_query, *values)
        @@database.get_first_value(sql_query, *values)
    end

    def self.last_inserted_id
        @@database.get_first_value("SELECT last_insert_rowid();")
    end

    def self.close_statement(id, task_name)
        @@insert_statement.execute(task_name)
        @@stats[id]['end_time'] = Time.now
        @@completed_tasks[id] << id

        @@statements[id].reset!
        @@statements[id].close
        @@semaphore.synchronize { @@statements.delete(id) }
        @@logger.info("statement '#{id}' has been closed")
    end

    def self.wait_task_completion(id)
        # wait till task is completed
        @@completed_tasks[id].pop
    end

    def self.get_task_stats(id)
        @@stats[id]
    end

    def self.start_transaction
        unless @@database.transaction_active?
            @@logger.info('going to start transaction')
            @@database.transaction
        end
    end

    def self.commit_transaction
        if @@database.transaction_active?
            @@logger.info('going to commit transaction')
            @@database.commit
        end
    end

    def self.close_database
        @@statements.keys.each do |key|
            @@statements[key].reset!
            @@statements[key].close
            @@statements.delete(key)

            @@completed_tasks[key] << 0
            @@logger.error("Forced to close '#{key}' statement")
        end

        unless @@insert_statement.nil?
            @@insert_statement.reset!
            @@insert_statement.close
        end

        self.commit_transaction
        @@database.close

        @@logger.info("processed #{@@stats['db_inserts']} inserts")
        @@logger.info('closing database')
        @@logger.finish_logging
    end

    def self.close
        @@thread.join
    end

    def self.get_client(params = {})
        Portage3::Database::Client.new(params)
    end

    def self.create_db_name
        "portage-cache-#{Utils.get_timestamp}.#{EXT}"
    end
end

class Portage3::Database::Client
    SERVER = Portage3::Database

    def initialize(params = {})
        if params.has_key?('db_filename')
            Portage3::Database.init(params['db_filename'])
        end

        if params.has_key?('id') && params['id'].is_a?(String) && !params['id'].empty?
            @id = params['id']
        else
            @id = Digest::MD5.hexdigest(Random.rand.to_s)
        end

        @id_hash = {'id' => @id}

        self
    end

    def validate_query(query)
        SERVER.validate_query(@id, query)
    end

    def insert(params)
        params = {'data' => params} unless params.is_a?(Hash)
        SERVER.add_data4insert(params.merge(@id_hash))
    end

    def execute(sql_query, *values)
        SERVER.execute(sql_query, *values)
    end

    def safe_execute(*values)
        SERVER.safe_execute(*values)
    end

    def select(sql_query, *values)
        SERVER.select(sql_query, *values)
    end

    def get_1value(sql_query, *values)
        SERVER.get_1value(sql_query, *values)
    end

    def insert_end(task_name)
        insert(['DB:EOT', task_name])
    end

    # TODO useless?
    def start_transaction
        SERVER.start_transaction
    end

    def commit_transaction
        SERVER.commit_transaction
    end

    def wait_4_end_confirmation
        SERVER.wait_task_completion(@id)
    end

    def get_stats
        SERVER.get_task_stats(@id)
    end

    def shutdown_server
        insert(['DB:EOS'])
        SERVER.close
    end
end

