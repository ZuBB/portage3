#!/usr/bin/env ruby

current_dir = File.dirname(__FILE__)
$:.push File.expand_path(File.join(current_dir, '..', 'lib'))
$:.push File.expand_path(File.join(current_dir, '..', 'lib', 'portage'))

require 'portage3'
require 'profiles'
require 'useflag'

ITEMS = ['use.force', 'use.mask']

def process_file(filename, profile)
    return unless File.size?(filename)
    filename = File.realpath(filename)

    IO.readlines(filename)
    .reject { |line| /^\s*#/ =~ line }
    .reject { |line| /^\s*$/ =~ line }
    .map { |line| line.strip }
    .each do |line|
        flag = UseFlag.get_flag(line)
        unless @flags.include?(flag)
            puts "#{filename} - #{flag}"
        end
    end
end

def process_dir(path, profile)
    return if File.exist?(File.join(path, 'deprecated'))

    # we need to add base dir of profile also as source of data
    if File.size?(new_parent = File.join(path, 'parent'))
        IO.read(new_parent).lines.each do |relative_path|
            next if /^\s*#/ =~ relative_path
            next if /^\s*$/ =~ relative_path
            relative_path.strip!

            new_path = File.join(path, relative_path)
            process_dir(File.realpath(new_path), profile)
        end
    end

    use_force_file = File.join(path, ITEMS[0])
    use_mask_file = File.join(path, ITEMS[1])
    if File.exist?(use_force_file) || File.exist?(use_mask_file)
        process_file(use_force_file, profile)
        process_file(use_mask_file, profile)
    end
end

def process_item(profile)
    profile_path = File.join(Utils::get_profiles_home, profile)

    return unless File.exist?(profile_path)
    return if File.file?(profile_path)

    process_dir(profile_path, profile)
end

Portage3::Logger.start_server
Portage3::Database.init(Utils.get_database)
db = Portage3::Database.get_client
@flags = db.select('select name from flags').flatten
db.select(PProfile::SQL['names'])
.flatten.each { |profile| process_item(profile) }

