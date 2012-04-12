#!/usr/bin/env ruby
#
# Helper script that puts unpacked portage tree
# to the directory in the fast storage (tmpfs)
#
# Initial Author: Vasyl Zuzyak, 01/05/12
# Latest Modification: Vasyl Zuzyak, ...
#
curr_dir = File.dirname(__FILE__);
$:.push File.expand_path(File.join(curr_dir, '..', 'lib'))
require 'fileutils'
require 'optparse'
require 'utils'

options = {
    "download_snapshot" => false,
    "download_url" => 'http://de-mirror.org/gentoo/snapshots/portage-latest.tar.bz2',
    "recreate_tree" => false,
    "snapshots_home" => '../misc/snapshots',
    "snapshot_name" => 'portage-latest.tar.bz2',
    "quiet" => false
}

# lets merge stuff from tools lib
options = {}.merge!(Utils::OPTIONS).merge!(options)

OptionParser.new do |opts|
    # help header
    opts.banner = " Usage: prepare_fast_storage [options]"
    opts.separator "\n A script that puts portage tree to own directory in the fast storage"
    opts.separator " Default is a shared memory (tmpfs), mounted at /dev/shm"
    opts.separator "\n Command line options"

    opts.on("-d", "--download-snapshot", "Redownload latest snapshot") do |value|
        # if we dowloading new snapshot, we need to recreate tree
        options["download_snapshot"] = options["recreate_tree"] = true
    end

    opts.on("-f", "--root-folder STRING", "Dir where portage tree will be extracted") do |value|
        options["storage"]["root"] = File.expand_path(value)
    end

    opts.on("-r", "--recreate-tree", "Recreate portage tree") do |value|
        options["recreate_tree"] = true
    end

    opts.on("-u", "--url STRING", "URL for downloading snapshot") do |value|
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

    opts.on("-q", "--[no-]quiet", "Quiet mode") do |value|
        options["quiet"] = value
    end

    opts.on_tail("-h", "--help", "Show this message") do
        puts opts
        exit
    end
end.parse!

root_path = options["portage_home"]
full_path = File.join(root_path, options["home_folder"])

print "Checking if '#{root_path}' path is present on target system.. "
if File.exist?(root_path)
    puts "OK"
else
    puts "\nERROR: '#{root_path}' location can not be found on target system"
    exit(1)
end

print "Checking if '#{root_path}' is a directory on target system.. "
if File.directory?(root_path)
    puts "OK"
else
    puts "\nERROR: '#{root_path}' is not a directory on target system"
    exit(1)
end

print "Checking if '#{root_path}' is writable on target system.. "
if File.writable?(root_path)
    puts "OK"
else
    puts "\nERROR: '#{root_path}' is not writable on target system"
    exit(1)
end

print "Checking if '#{root_path}' has enough space on target system.. "
space_line = `df -kP #{root_path}`.split("\n")[1]
space_available = space_line.split(" ")[3].to_i
portage_size = `du -s #{root_path}`.split(' ')[0].to_i if File.exist?(root_path)
required_space = options["required_space"] * 1024

if space_available > required_space
    puts "OK"
elsif File.exist?(full_path) && portage_size + space_available > required_space
    puts "OK"
else
    puts "\nERROR: '#{root_path}' does not have enough space"
    exit(1)
end

soft_link = File.join(
    curr_dir, options["snapshots_home"], options["snapshot_name"]
)

if options["download_snapshot"]
    print "Starting download portage snapshot.. "
    puts if !options["quiet"]
    STDOUT.flush

    # check if download directory exists
    download_dir = File.join(curr_dir, options["snapshots_home"])
    Dir.mkdir(download_dir) unless File.exist?(download_dir)

    # get correct filename
    filename = File.join(
        download_dir,
        (options["download_url"].include?('latest') ?
             options["snapshot_name"].gsub("latest", Utils.get_timestamp()) :
             File.basename(options["download_url"])
        )
    )

    # create wget command
    wget_command = "wget -O #{filename}"
    wget_command << " #{options["quiet"] ? '-q' : ''}"
    wget_command << " #{options["download_url"]}"

    # download new snapshot
    %x[#{wget_command}]
    puts 'Done' if options["quiet"]

    # remove outdated one
    if File.exist?(soft_link)
        File.delete(File.join(
            curr_dir, options["snapshots_home"], File.readlink(soft_link)
        ))
    end

    # update softlink
    `ln -fs #{File.basename(filename)} #{soft_link}`
end

if options["recreate_tree"] || !File.exist?(full_path)
    FileUtils.rm_r(full_path) if File.exist?(full_path)
    print "Starting exctact portage snapshot.. "
    STDOUT.flush
    `tar xjf #{soft_link} -C #{root_path}`
    puts "Done"
elsif File.exist?(full_path)
    puts "Portage dir already present"
    puts "Its size equals to #{portage_size / 1024} Mb"
    puts "It has #{Dir.glob(full_path + '/*/').size} subdirectories inside"
    puts "HINT: use '-h' option to see help"
end
