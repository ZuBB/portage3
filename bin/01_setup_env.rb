#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/06/12
# Latest Modification: Vasyl Zuzyak, ...
#

scripts_dir = File.join(File.dirname(__FILE__), "env_setup")

Dir.glob(File.join(scripts_dir, "/*.rb")).sort.each do |script|
    `#{script}` if /\d\d_[\w_]+\.rb$/ =~ script
end

