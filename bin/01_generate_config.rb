#!/usr/bin/env ruby
#
# Helper script that puts unpacked portage tree
# to the directory in the fast storage (tmpfs)
#
# Initial Author: Vasyl Zuzyak, 01/05/12
# Latest Modification: Vasyl Zuzyak, ...
#
require_relative '../lib/common/parser'
require 'rubygems'
require 'json'

def get_deploy_type(deployment_objs, deploy_type)
    message_parts = ['Select deployment type']
    deployments = deployment_objs.keys.sort
    deployments.each { |depl|
        message_parts << "[#{(deployments.index(depl) + 1).to_s}] #{depl}:"\
            " #{deployment_objs[depl]['description']}"
    }

    message_parts << "Default one (#{deploy_type}) is highly recommended: "
    print(message_parts.join("\n"))
    reply = Integer(gets.strip) rescue 1
    reply = 1 if reply < 1 || reply > deployments.size
    deployments[reply - 1]
end

def get_overlay_support(overlay_support)
    message_parts = ['Enable overlay support']
    unless overlay_support.nil?
        default_value = overlay_support ? 'Yes' : 'No'
        message_parts << " (recommended is '#{default_value}')"
    end
    message_parts << "? Yes/No: "
    print(message_parts.join)
    ['yes', 'y'].include?(gets.strip.downcase)
end

def run_checks(settings_dir, example_file, settings_file)
    unless File.size?(settings_file).nil?
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

def gentoo_os?
    output = `whereis emerge`.strip
    output.split.drop(1).any? { |item| item.eql?('/usr/bin/emerge') }
end

def get_emerge_info
    `emerge --info`.strip
end

def get_profile
    `eselect --brief profile show`.strip
end

config_path_parts = [File.dirname(__FILE__), '../', 'data']
settings_dir = File.expand_path(File.join(*config_path_parts))
settings_file = File.join(settings_dir, 'settings.json')
example_file = File.join(File.dirname(__FILE__), 'example.json')
run_checks(settings_dir, example_file, settings_file)

begin
    data = JSON.parse(IO.read(example_file))
rescue Exception => e
    puts e.message
    exit(1)
end

if (data['gentoo_os'] = gentoo_os?) == true
    print 'Getting output of `emerge --info`..'
    STDOUT.flush

    emerge_info = get_emerge_info
    puts ' Done'

    emerge_info << "\nPROFILE=#{get_profile}"
    File.open(File.join(settings_dir, 'emerge_info'), 'w') { |file|
        file.write(emerge_info)
    }

    sys_tree_home = Parser.get_multi_line_ini_value(emerge_info.split("\n"), 'PORTDIR')
    unless File.exist?(sys_tree_home) && File.directory?(sys_tree_home)
        sys_tree_home = "/usr/portage"
    end

    data['deployments'].each_value do |deployment|
        if deployment['tree_home'].include?('${PORTDIR}')
            deployment['tree_home'] = sys_tree_home
        end
    end

    data['overlay_support'] = get_overlay_support(data['overlay_support'])
else
    data['overlay_support'] = false
end

data_dir_path = File.absolute_path(File.join(File.dirname(__FILE__), '..'))
data['deployments'].each_value do |deployment|
    deployment.each_value do |path|
        path.sub!('${APPROOT}', data_dir_path)
    end
end

deploy_type = get_deploy_type(data['deployments'], data['deploy_type'])
data['deployments'][deploy_type].each { |key, value| data[key] = value }
['deployments', 'deploy_type'].each { |item| data.delete(item) }
data.delete('description')
data['uuid'] = `cat /proc/sys/kernel/random/uuid`.strip

File.open(settings_file, 'w') { |file|
    file.write(JSON.pretty_generate(data))
}
