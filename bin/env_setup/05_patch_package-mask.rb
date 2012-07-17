#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 02/06/12
# Latest Modification: Vasyl Zuzyak, ...
#
require_relative 'envsetup'

# hash with options
package_mask_file = File.join(Utils.get_profiles2_home, 'base/package.mask')

# remove uclibc
line_num = `grep -nh '^sys-libs/uclibc' #{package_mask_file} | sed 's/:.*//'`
`sed -i.bak -e '#{line_num.chomp!}d' #{package_mask_file}`

