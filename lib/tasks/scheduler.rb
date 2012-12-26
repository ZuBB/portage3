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

Encoding.default_external = 'UTF-8'
Encoding.default_internal = 'UTF-8'

class Tasks::Scheduler
    TAKS_INDEX = /^Task_(\d{3})/
    PORT       = 8134
    SQL = {
        'check' => 'select count(id) from completed_tasks where name = ?;',
    }

    @@database = nil
    @@shared_data = {}
    @@semaphore = Mutex.new

    def initialize(params)
        @db_client   = nil
        @options    = params
       #@shared_data = {}
        @start_time = Time.now
        @task_specs = {
            'all'   => {},
            'deps'  => {},
            'rdeps' => {},
            'pids'  => {},
            '2run'  => [],
            '4run'  => []
        }

        create_communication_pipes

        account_all_tasks
        get_dependencies
        get_reverse_dependencies

        expand_skip_param
        #expand_task_by_index
    end

    def run_specified_tasks
        return if (@task_specs['2run'] = get_tasks_by_range.dup).empty?

        if dead_dependencies?
            @logger.error("Unsatisfied dependencie(s). have to terminate")
            return false
        end

        while @task_specs['2run'].size > 0
            @task_specs['2run'].map! do |name|
                # if task does not have deps - run it
                if @task_specs['deps'][name].nil?
                    name = run_task(name)
                # if task has deps and they were satisfied on prev session
                elsif deps_satisfied_by_prev_session?(name)
                    name = run_task(name)
                # if task's deps already not running
                elsif !deps_already_finished?(name)
                    # and all deps satisfied - lets run it
                    if task_dependencies_satisfied?(name)
                        name = run_task(name)
                    end
                end
                # TODO runtime dead deps

                name
            end
            @task_specs['2run'].compact!
            sleep(0.5) unless @task_specs['2run'].empty?
        end
    end

    def finalize
        @task_specs['pids'].values.each { |pid|
            if self.class.process_running?(pid)
                Process.waitpid(pid, 0)
            end
        }

        @db_client.shutdown_server

        @logger.info("Total passed: #{(Time.now - @start_time)} seconds")
        @logger.finish_logging
        Portage3::Logger.shutdown_server

       #@server_thread.kill
    end

    private
    def create_communication_pipes
        @id = Digest::MD5.hexdigest(self.class.name)

        Portage3::Logger.start_server unless @options['connection']

        @db_client = @options['connection'] ?
            @options['connection'] :
            Portage3::Database.get_client({
                'db_filename' => @options['db_filename'],
                'id' => @id
            })

        @logger = Portage3::Logger.get_client({
            'file' => self.class.name,
            'id'   => @id
        })

if false
        # shared_data server
        server = TCPServer.new('localhost', PORT)
        Thread::abort_on_exception = true
        @server_thread = Thread.new do
            loop do
                Thread.start(server.accept) do |connection|
                    process_connection(connection)
                end
            end
end
        end
    end

    def account_all_tasks
        Tasks.constants.select { |class_name|
            class_name.to_s.start_with?(Tasks::TASK_NAME_PREFIX)
        }.each { |class_name|
            @task_specs['all'][class_name.to_s] = Tasks.const_get(class_name)
        }

        if @options['task_filenames'].size != @task_specs['all'].size
            unless @options['quiet']
                # TODO log this
                puts "#{diff} task(s) have issue with filename/class name"
            end
        end
    end

    def get_dependencies
        @task_specs['all'].each do |name, task|
            next unless task.const_defined?('DEPENDS')
            next unless task::DEPENDS.is_a?(String)

            raw_dependencies = task::DEPENDS.split(/;\ ?/).sort
            @task_specs['deps'][name] = raw_dependencies.map { |dep|
                Tasks::TASK_NAME_PREFIX + dep
            }
        end
    end

    def get_reverse_dependencies
        @task_specs['deps'].each do |name, deps_array|
            deps_array.each do |dependency|
                unless @task_specs['rdeps'].has_key?(dependency)
                    @task_specs['rdeps'][dependency] = []
                end
                @task_specs['rdeps'][dependency] << name
            end
        end
    end

    def dead_dependencies?
        all_required_dependencies = []

        @task_specs['2run'].each { |scheduled_task|
            next unless @task_specs['deps'].has_key?(scheduled_task)

            @task_specs['deps'][scheduled_task].each { |dependency|
                all_required_dependencies << dependency
            }
        }

        satisfied_dependencies = get_tasks_satisfied_dependencies
        all_satisfied_dependencies = satisfied_dependencies + @task_specs['2run']

        all_required_dependencies.any? { |dependency|
            !all_satisfied_dependencies.include?(dependency)
        }
    end

    def deps_satisfied_by_prev_session?(name)
        scheduled = @task_specs['deps'][name].any? { |dependency|
            @task_specs['4run'].include?(dependency)
        }

        return false if scheduled
        task_dependencies_satisfied?(name)
    end

    def deps_already_finished?(name)
        @task_specs['deps'][name].all? { |task|
            Tasks::Scheduler.process_finished?(@task_specs['pids'][task])
        }
    end

    def task_dependencies_satisfied?(name)
        satisfied_dependencies = get_tasks_satisfied_dependencies([name])

        result = satisfied_dependencies.sort == @task_specs['deps'][name]
        @logger.info("#{name}: passed deps check") if result

        result
    end

    def get_tasks_satisfied_dependencies(task_names = @task_specs['2run'])
        satisfied_dependencies = []

        task_names.each { |scheduled_task|
            next unless @task_specs['deps'].has_key?(scheduled_task)

            @task_specs['deps'][scheduled_task].each do |dependency|
                count = @db_client.get_1value(SQL['check'], dependency)
                satisfied_dependencies << dependency if count == 1
            end
        }

        satisfied_dependencies.uniq
    end

    def run_task(name)
        @logger.info("#{name}: will start in a moment")
        @task_specs['pids'][name] = fork do
            @task_specs['all'][name].new({
                'name'        => name,
                'debug'       => @options['debug'],
                'db_filename' => @options['db_filename']
            })
        end
        nil
    end

    def expand_skip_param
        return if @options['skip'].empty?
        @options['skip'] = @options['skip']
        .split(',')
        .map do |i|
            if i.include?('-')
                ends = i.split('-')
                (ends[0]..ends[1]).to_a
            else
                i
            end
        end
        .flatten
        .map { |i| i.to_i }
    end

    def expand_task_by_index
        #@all_tasks.keys.select do |name|
            #name.to_s.match(/^\d{3}/).to_a[0].to_i == options["task"]
        #end
    end

    def get_tasks_by_range
        # TODO fix bug with 0 tasks to run
        _from  = @options['from']
        _skip  = @options['skip']
        _until = @options['until']

        @task_specs['4run'] = @task_specs['all']
        .keys
        .select { |name| self.class.get_task_index(name) >= _from }
        .select { |name| self.class.get_task_index(name) < _until }
        .reject { |name| _skip.include?(self.class.get_task_index(name)) }
    end

    def process_connection(connection)
        required_keys = ['key', 'query']

        while accepted_string = connection.gets
            begin
                json_object = JSON.parse(accepted_string)
            rescue
                @logger.error('Failed to parse next incoming string')
                @logger.info(accepted_string)
                next
            end

            unless required_keys.all? { |key| json_object.has_key?(key) }
                @logger.warn('incoming object does not have all params')
                next
            end

            key   = json_object['key']
            query = json_object['query']

            have_data = @mutex.synchronize {
                @shared_data.include?(key)
            }

            unless have_data
                @mutex.synchronize {
                    @shared_data[key] = Hash[@database.get({
                        'action' => 'get_select',
                        'params' => [query]
                    })]
                }
            end

            connection.puts(JSON.generate({'result' => @shared_data[key]}))
        end
    end

    def self.get_task_index(symbol)
        symbol.to_s.match(TAKS_INDEX).to_a[1].to_i
    end

    def self.process_running?(pid)
        (Process.waitpid(pid, Process::WNOHANG) rescue false).nil?
    end

    def self.process_finished?(pid)
        (Process.kill(0, pid) rescue 0).zero?
    end

    def self.create_client_socket
        TCPSocket.open("localhost", PORT)
    end

    def self.set_shared_data(key, sql_query)
        unless @@semaphore.synchronize { @@shared_data.include?(key) }
            @@semaphore.synchronize {
                @@database = Portage3::Database::Client.new
                @@shared_data[key] = Hash[
                    @@database.get_and_close('select', sql_query)
                ]
            }
        end
    end
end

