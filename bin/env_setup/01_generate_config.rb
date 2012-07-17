#!/usr/bin/env ruby
#
# Helper script that puts unpacked portage tree
# to the directory in the fast storage (tmpfs)
#
# Initial Author: Vasyl Zuzyak, 01/05/12
# Latest Modification: Vasyl Zuzyak, ...
#
require_relative 'envsetup'

config_path_parts = [File.dirname(__FILE__), EnvSetup.get_path2root, 'config']
settings_dir = File.expand_path(File.join(*config_path_parts))
settings_file = File.join(settings_dir, 'settings.json')
example_file = File.join(settings_dir, 'example.json')

if File.exist?(settings_file) && File.size(settings_file) > 0
    puts('Settings already generated')
    exit(0)
end

unless File.exist?(example_file)
    print('Can not find settings example')
    exit(1)
end

unless  File.writable?(settings_dir)
    print('Settings dir is not writable')
    exit(1)
end

data = JSON.parse(IO.read(example_file))

# generate uuid for current system
data['uuid'] = `cat /proc/sys/kernel/random/uuid`.strip()
# TODO: recheck all values that might be different on target PC

File.open(settings_file, 'w') do |file|
    file.write(JSON.pretty_generate(data))
end

