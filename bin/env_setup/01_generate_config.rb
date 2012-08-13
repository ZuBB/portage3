#!/usr/bin/env ruby
#
# Helper script that puts unpacked portage tree
# to the directory in the fast storage (tmpfs)
#
# Initial Author: Vasyl Zuzyak, 01/05/12
# Latest Modification: Vasyl Zuzyak, ...
#
require_relative 'envsetup'

def get_users_deploy_type(data)
    message_part = ''
    deployments = data['deployments'].keys
    deployments.each { |depl|
        idx = (deployments.index(depl) + 1).to_s
        message_part += "[#{idx}] #{depl}\n"
    }

    message = "Select deployment type\n"\
        "#{message_part}"\
        "Default one (#{data['deploy_type']}) is highly recommended: "

    print(message)
    deployment = gets.strip.to_i == 2 ? 'production' : 'debug'

    data['deployments'][deployment].each { |key, value|
        data[key] = value
    }
    data.delete('deployments')
    data.delete('deploy_type')

    data
end

def get_users_overlay_support(data)
    mp = data['overlay_support'] ? 'yes' : 'no'
    message = "\nEnable overlay support (recommended is #{mp})? Y[es]/N[o]: "
    print(message)
    ['yes', 'y'].include?(gets.strip.downcase)
end

def checks(settings_file, example_file, settings_dir)
    unless File.size?(settings_file)
        puts('Settings already generated')
        exit(0)
    end

    unless File.exist?(example_file)
        puts('Can not find settings example')
        exit(1)
    end

    unless  File.writable?(settings_dir)
        puts('Settings dir is not writable')
        exit(1)
    end
end

config_path_parts = [File.dirname(__FILE__), EnvSetup.get_path2root, 'config']
settings_dir = File.expand_path(File.join(*config_path_parts))
settings_file = File.join(settings_dir, 'settings.json')
example_file = File.join(settings_dir, 'example.json')

checks(settings_file, example_file, settings_dir)
file_content = IO.read(example_file)

begin
    data = JSON.parse(file_content)
rescue
    puts('Failed to parse settings example')
    exit(1)
end

data = get_users_deploy_type(data)
data['overlay_support'] = get_users_overlay_support(data)
data['uuid'] = `cat /proc/sys/kernel/random/uuid`.strip()

# TODO: recheck all values that might be different on target PC

File.open(settings_file, 'w') do |file|
    file.write(JSON.pretty_generate(data))
end

