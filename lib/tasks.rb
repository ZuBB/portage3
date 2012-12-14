module Tasks
    # should match next regexp ^[A-Z][\w]*
    TASK_NAME_PREFIX = 'Task_'

    def self.create_task(filename, klass)
        class_name = "#{TASK_NAME_PREFIX}#{File.basename(filename, '.rb')}"
        self.const_set(class_name, klass)
    end
end

require 'tasks/runner'
require 'tasks/scheduler'
