#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/11/12
# Latest Modification: Vasyl Zuzyak, 01/11/12
#
$:.push File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'fileutils'
require 'tools'

# hash with options
options = Hash.new.merge!(OPTIONS)
portage_home = get_full_tree_path(options)
FileUtils.cd(portage_home)
profiles_file = 'profiles_v2/profiles.desc'

%x[sed -i.bak "s/default\\/linux\\/amd64/amd64\\/linux\\/default/" #{profiles_file}]
%x[sed -i.bak "s/default\\/linux\\/x86/x86\\/linux\\/default/" #{profiles_file}]

