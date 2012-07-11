#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 02/06/12
# Latest Modification: Vasyl Zuzyak, ...
#
$:.push File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib', 'common'))
require 'fileutils'
require 'utils'

# hash with options
options = Hash.new.merge!(Utils::OPTIONS)
# change dir to `home of the new portage data`
FileUtils.cd(Utils.get_full_tree_path(options))
profiles_file = 'profiles_v2/profiles.desc'

%x[sed -i.bak "s/default\\/linux\\/amd64/amd64\\/linux\\/default/" #{profiles_file}]
%x[sed -i.bak "s/default\\/linux\\/x86/x86\\/linux\\/default/" #{profiles_file}]
