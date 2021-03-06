#!/usr/bin/env ruby
#
# Helper script that puts unpacked portage tree
# to the directory in the fast storage (tmpfs)
#
# Initial Author: Vasyl Zuzyak, 01/05/12
# Latest Modification: Vasyl Zuzyak, ...
#
require 'fileutils'
require 'optparse'
require_relative '../lib/common/parser'
require_relative '../lib/common/utils'

options = {
    "download_snapshot" => false,
    "download_url" => 'http://goo.gl/o0kHa',
    "snapshots_home" => '../data/snapshots',
    "snapshot_name" => 'portage-latest.tar.bz2',
    "required_space" => 700,
    "recreate_tree" => false,
    "sync_tree" => Utils::SETTINGS['gentoo_os']
}

# lets merge stuff from tools lib
options.merge!(Utils::OPTIONS)

OptionParser.new do |opts|
    # help header
    opts.banner = " Usage: prepare_fast_storage [options]"
    opts.separator "\n A script that puts portage tree to own directory in the fast storage"
    opts.separator " Default is a shared memory (tmpfs), mounted at /dev/shm"
    opts.separator "\n Command line options"

    opts.on("-d", "--download-snapshot", "Download latest snapshot (implies -r)") do |value|
        # if we dowloading new snapshot, we need to recreate tree
        options["download_snapshot"] = options["recreate_tree"] = true
    end

    opts.on("-r", "--[no-]recreate-tree", "Recreate portage tree") do |value|
        options["recreate_tree"] = value
    end

    if Utils::SETTINGS['gentoo_os']
        opts.on("-s", "--[no-]sync-tree", "Sync downloaded tree with system's one (default is true)") do |value|
            options["sync_tree"] = value
        end
    end

    opts.on("-u", "--url STRING", "URL for downloading custom portage snapshot") do |value|
        if value[-7..-1] == 'tar.bz2'
            # if we got new dowload url,
            options["download_url"] = value
            # we need to download new snapshot and recreate tree
            options["download_snapshot"] = options["recreate_tree"] = true
        else
            puts 'Script workds only with `bz2` archives'
            exit(2)
        end
    end

    opts.on_tail("-h", "--help", "Show this message") do
        puts opts
        exit
    end
end.parse!

sys_tree_home = nil
settings = Utils.get_settings
portage_home = Utils.get_tree_home
root_path = File.dirname(portage_home)

if Utils::SETTINGS['gentoo_os']
    sys_tree_home = Parser.get_multi_line_ini_value(
        IO.readlines(File.join(
            File.dirname(__FILE__),
            '../',
            'data',
            'emerge_info'
        )), 'PORTDIR'
    )
end

unless File.exist?(root_path)
    puts "\nERROR: '#{root_path}' location can not be found on target system"
    exit(1)
end

unless File.directory?(root_path)
    puts "\nERROR: '#{root_path}' is not a directory on target system"
    exit(1)
end

if portage_home != sys_tree_home && !File.writable?(root_path)
    puts "\nERROR: '#{root_path}' is not writable on target system"
    exit(1)
end

space_available = `df -kP #{root_path}`.split("\n")[1].split(" ")[3].to_i
portage_size = `du -s #{portage_home} 2> /dev/null`.split[0].to_i rescue 0
required_space = options["required_space"] * 1024

if portage_size + space_available < required_space
    puts "\nERROR: '#{root_path}' does not have enough space"
    exit(1)
end

snapshots_home = File.expand_path(
    File.join(File.dirname(__FILE__), options["snapshots_home"])
)

if !File.exist?(snapshots_home)
    Dir.mkdir(snapshots_home)
end

soft_link = File.join(snapshots_home, options["snapshot_name"])

if options["download_snapshot"] || Dir[snapshots_home].size == 0
    print "Starting download portage snapshot.. "
    STDOUT.flush

    # get correct filename
    filename = File.join(soft_link.sub("latest", Utils.get_timestamp))

    # download new snapshot
    %x[wget -q -O #{filename} #{options['download_url']}]
    puts 'Done'

    # remove outdated one
    if File.exist?(soft_link)
        File.delete(File.join(snapshots_home, File.readlink(soft_link)))
    end

    # update softlink
    `ln -fs #{File.basename(filename)} #{soft_link}`
end

if portage_size > 0 && !options["recreate_tree"] && !options['sync_tree']
    puts "Portage dir already present"
    puts "It has #{Dir.glob(portage_home + '/*/').size} subdirectories inside"
    puts "Its size equals to #{portage_size / 1024} Mb"
    puts "HINT: use '-h' option to see help"
end

if options["recreate_tree"] || !File.exist?(portage_home)
    unless File.size?(soft_link)
        puts 'something is wrong with snapshot. please redownload it'
        exit(false)
    end

    if portage_home == sys_tree_home
        puts "Can not modify #{portage_home}!"
        exit(false)
    end

    print "Starting exctact portage snapshot.. "
    FileUtils.rm_r(portage_home) if File.exist?(portage_home)
    STDOUT.flush
    `tar xjf #{soft_link} -C #{root_path}`
    puts "Done"
end

if options['sync_tree']
    if portage_home == sys_tree_home
        puts "Can not modify #{portage_home}!"
        exit(false)
    end

    print "Starting syncing portage snapshot with system tree.. "
    STDOUT.flush
    command = 'rsync -a --delete'
    command << " --exclude=distfiles"
    command << " --exclude=packages"
    command << " #{sys_tree_home} #{root_path}"
    %x[#{command}]
    # deleting `Changelog` files..
    %x[rm #{portage_home}/*-*/*/ChangeLog]
    puts "Done"
end
