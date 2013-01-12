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
    SQL = {
        'check' => 'select count(id) from completed_tasks where name = ?;',
    }

    @@database = nil
    @@shared_data = {}
    @@semaphore = Mutex.new

    def initialize(params)
        @db_client   = nil
        @options    = params
        @start_time = Time.now
        @task_specs = {
            'all'   => {},
            'pri'   => {},
            'sort'  => [],
            'deps'  => {},
            'rdeps' => {},
            'trds'  => {},
            '2run'  => [],
        }

        create_communication_pipes

        account_all_tasks
        get_dependencies
        get_reverse_dependencies
        set_tasks_priorities
        sort_tasks_by_pri
    end

    def run_specified_tasks
        @task_specs['2run'] = @task_specs['all'].keys

        if dead_dependencies?
            @logger.error("Unsatisfied dependencie(s). have to terminate")
            return false
        end

        @task_specs['sort'].each do |name|
            run_task(name)
        end
    end

    def finalize
        @task_specs['trds'].values.each { |task|
            @logger.info("#{task['name']}: attempt to do a 'join'")
            task.join
            @logger.info("#{task['name']}: attempt successful")
        }

        @db_client.shutdown_server

        @logger.info("Total passed: #{(Time.now - @start_time)} seconds")
        @logger.finish_logging
        Portage3::Logger.shutdown_server
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
    end

    def account_all_tasks
        Tasks.constants.select { |class_name|
            class_name.to_s.start_with?(Tasks::TASK_NAME_PREFIX)
        }.each { |class_name|
            task_name = class_name.to_s
            @task_specs['all'][task_name] = Tasks.const_get(class_name)
            @task_specs['pri'][task_name] = 0
        }

        # TODO do we need this?
        if @options['task_filenames'].size != @task_specs['all'].size
            diff = @options['task_filenames'].size - @task_specs['all'].size
            message = "#{diff} task(s) have issue with filename/class name"
            @logger.warn(message)
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

    def set_tasks_priorities
       @task_specs['rdeps'].each_key do |key|
           task_pri = get_task_priority(key, 1)
           pri_index = @task_specs['all'][key].const_get(:PRI_INDEX) rescue 1
           @task_specs['pri'][key] = (task_pri * pri_index).round
       end
    end

    def get_task_priority(task, level)
        return 0 unless @task_specs['rdeps'].has_key?(task)

        task_pri = @task_specs['rdeps'][task].size * level

        @task_specs['rdeps'][task].each { |subtask|
            task_pri += get_task_priority(subtask, level + 1)
        }

        task_pri
    end

    def sort_tasks_by_pri
        @task_specs['sort'] = @task_specs['pri'].to_a
        .sort { |a, b| b[1] <=> a[1] }
        .sort { |a, b| b[1] == a[1] ? a[0] <=> b[0] : b[1] <=> a[1] }
    end

    def run_task(name)
        name, pri = *name
        @task_specs['trds'][name] = Thread.new do
            @logger.info("#{name}: started")

            Thread.current.priority = pri
            Thread.current['deps'] = []
            Thread.current['name'] = name
            Thread.current['queue'] = Queue.new

            check_task_dependencies(name)

            # TODO other params
            params = {}
            params['name'] = name
            params['start'] = Time.now

            @task_specs['all'][name].new(params)
            send_signal2deps(name)

            @logger.info("#{name}: I am really done")
        end
    end

    def get_task_by_index
        @all_tasks.keys.select do |name|
            name.to_s.match(/^\d{3}/).to_a[0].to_i == options["task"]
        end
    end

    def self.get_task_index(symbol)
        symbol.to_s.match(TAKS_INDEX).to_a[1].to_i
    end

    def check_task_dependencies(name)
        @logger.info("#{name}: checking dependencies")

        if @task_specs['deps'].has_key?(name)
            @task_specs['deps'][name].each do |dependency|
                count = @db_client.get_1value(SQL['check'], dependency)
                Thread.current['deps'] << dependency if count == 1
            end

            while Thread.current['deps'].uniq.sort != @task_specs['deps'][name]
                Thread.current['deps'] << Thread.current['queue'].pop
            end
        end

        @logger.info("#{name}: passed dependency check")
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

    def send_signal2deps(name)
        return unless @task_specs['rdeps'].has_key?(name)

        @task_specs['rdeps'][name].each do |d|
            if @task_specs['trds'].has_key?(d)
                @logger.info("#{name} says to #{d}: I am done")
                @task_specs['trds'][d]['queue'] << name
            end
        end
    end

    def self.expand_skip_param(skip)
        skip.split(',')
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

    def self.set_shared_data(key, sql_query)
        if @@database.nil?
            @@database = Portage3::Database::get_client
        end

        unless @@semaphore.synchronize { @@shared_data.include?(key) }
            @@semaphore.synchronize {
                @@shared_data[key] = Hash[@@database.select(sql_query)]
            }
        end
    end
end
