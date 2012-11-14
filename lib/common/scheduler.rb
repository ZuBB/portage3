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
require 'thread'
require 'digest/md5'

require 'runner'
require 'database'
require 'plogger'
require 'utils'

Encoding.default_external = 'UTF-8'
Encoding.default_internal = 'UTF-8'

class Tasks::Scheduler
    SQL = {
        'check' => 'select count(id) from completed_tasks where name = ?;',
        'insert' => 'insert or ignore into completed_tasks (name) VALUES (?);'
    }

    @@shared_data = {}
    @@semaphore = Mutex.new

    def initialize(params)
        @id = Digest::MD5.hexdigest(self.class.name + SQL['insert'])
        @options = params
        @all_tasks = {}
        @dependencies = {}
        @dependency_hash = {}
        @scheduled_tasks = {}
        @running_tasks = {}

        Database.init(@options['db_filename'])
        PLogger.init({
            'path'  => Utils.get_log_home,
            'dir'   => File.basename(@options['db_filename'], '.sqlite'),
            'level' => @options["debug"] ? Logger::DEBUG : Logger::INFO
        })

        PLogger.init_device({'file' => self.class.name, 'id' => @id})
        Database.validate_query(@id, SQL['insert'])

        Tasks.constants.select { |class_name|
            class_name.to_s.start_with?(Tasks::TASK_NAME_PREFIX)
        }.each { |class_name|
            @all_tasks[class_name.to_s] = Tasks.const_get(class_name)
        }

        if @options['task_filenames'].size != @all_tasks.size
            unless @options['quiet']
                puts "#{diff} task(s) have issue with filename/class name"
            end
        end
    end

    def get_dependencies
        @all_tasks.each do |name, task|
            if task.const_defined?('DEPENDS') && !task::DEPENDS.is_a?(String)
                unless @options['quiet']
                    puts "Task #{name} has constant 'DEPENDS' of wrong type"
                end
                next
            end

            @dependencies[name] = task.const_defined?('DEPENDS') ?
                task::DEPENDS.split(/;\ ?/).sort : []

            @dependencies[name].map! { |dependency|
                Tasks::TASK_NAME_PREFIX + dependency
            }
        end
    end

    def build_dependency_tree
        @dependencies.each do |name, deps_array|
            deps_array.each do |dependency|
                unless @dependency_hash.has_key?(dependency)
                    @dependency_hash[dependency] =  []
                end
                @dependency_hash[dependency] << name
            end
        end
    end

    def start_specified_tasks
        Thread.abort_on_exception = true

        get_tasks_by_range.each do |name|
            thread = Thread.new do
                PLogger.info(@id, "#{name}: started")

                Thread.current['deps'] = []
                Thread.current['name'] = name
                Thread.current['queue'] = Queue.new

                check_task_dependencies

                # TODO other params
                params = {}
                params['start'] = Time.now
                params['name'] = name

                @all_tasks[name].new(params)
                Database.add_data4insert({'id' => @id, 'data' => name})
                send_signal2deps(name)

                PLogger.info(@id, "#{name}: I am really done")
            end

            @running_tasks[name] = thread
        end

        @running_tasks.values.each { |task| task.join }

        Database.end_of_task(@id)
        PLogger.end_of_task(@id)

        Database.close
        PLogger.close
    end

    private
    def get_task_by_index
        @all_tasks.keys.select do |name|
            name.to_s.match(/^\d{3}/).to_a[0].to_i == options["task"]
        end
    end

    def get_tasks_by_range
        @scheduled_tasks = @all_tasks.keys.select do |name|
            name.to_s.match(/^Task_(\d{3})/).to_a[1].to_i >= @options["from"]
        end .select do |name|
            name.to_s.match(/^Task_(\d{3})/).to_a[1].to_i < @options["until"]
        end .reject do |name|
            @options['skip'].include?(name.to_s.match(/^Task_(\d{3})/).to_a[1].to_i)
        end
    end

    def check_task_dependencies
        name = Thread.current['name']

        @dependencies[name].each do |dependency|
            present = Database.get_1value(SQL['check'], dependency) == 1
            Thread.current['deps'] << dependency if present
        end

        inaccessible_dependency = @dependencies[name].any? { |dependency|
            !(
                @scheduled_tasks.include?(dependency) ||
                Thread.current['deps'].include?(dependency)
            )
        }

        if inaccessible_dependency
            message = "#{name}: unsatisfied dependencies. have to terminate"
            PLogger.error(@id, message)
            Thread.exit
        end

        while Thread.current['deps'].sort != @dependencies[name]
            Thread.current['deps'] << Thread.current['queue'].pop
        end

        PLogger.info(@id, "#{name}: passed deps check")
    end

    def send_signal2deps(name)
        if @dependency_hash.has_key?(name)
            @dependency_hash[name].each do |d|
                if @running_tasks.has_key?(d)
                    PLogger.info(@id, "#{name} says to #{d}: I am done")
                    @running_tasks[d]['queue'] << name
                end
            end
        end
    end

    def self.set_shared_data(key, sql_query)
        unless @@semaphore.synchronize { @@shared_data.include?(key) }
            @@semaphore.synchronize {
                @@shared_data[key] = Hash[Database.select(sql_query)]
            }
        end
    end
end

