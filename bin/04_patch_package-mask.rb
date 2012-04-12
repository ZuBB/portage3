#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 02/06/12
# Latest Modification: Vasyl Zuzyak, ...
#
$:.push File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'fileutils'
require 'utils'

# hash with options
options = Hash.new.merge!(Utils::OPTIONS)
# get home of the new portage data
FileUtils.cd(Utils.get_full_tree_path(options))
package_mask_file = 'profiles_v2/base/package.mask'

# remove uclibc
line_num = `grep -nh '^sys-libs/uclibc' #{package_mask_file} | sed 's/:.*//'`
`sed -i.bak -e '#{line_num.chomp!}d' #{package_mask_file}`

