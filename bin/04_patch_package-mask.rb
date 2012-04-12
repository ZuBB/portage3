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
package_mask_file = 'profiles_v2/base/package.mask'

# remove uclibc
line_num = `grep -nh '^sys-libs/uclibc' #{package_mask_file} | sed 's/:.*//'`
`sed -i.bak -e '#{line_num.chomp!}d' #{package_mask_file}`

line_num = `grep -nh 'celt\-0\.10$' #{package_mask_file} | sed 's/:.*//'`
`sed -i.bak -e '#{line_num.chomp!}d' #{package_mask_file}`
%x[sed -i.bak "s/=media-libs\\/celt-0.8.1/>=media-libs\\/celt-0.8.1/" #{package_mask_file}]
%x[sed -i.bak "s/=app-pda\\/libsyncml-9999/#=app-pda\\/libsyncml-9999/" #{package_mask_file}]
%x[sed -i.bak "s/=app-pda\\/libopensync-9999/#=app-pda\\/libopensync-9999/" #{package_mask_file}]
%x[sed -i.bak "s/=app-pda\\/osynctool-9999/#=app-pda\\/osynctool-9999/" #{package_mask_file}]
%x[sed -i.bak "s/=app-pda\\/libopensync-plugin-evolution2-9999/#=app-pda\\/libopensync-plugin-evolution2-9999/" #{package_mask_file}]
%x[sed -i.bak "s/=app-pda\\/libopensync-plugin-file-9999/#=app-pda\\/libopensync-plugin-file-9999/" #{package_mask_file}]
%x[sed -i.bak "s/=app-pda\\/libopensync-plugin-gnokii-9999/#=app-pda\\/libopensync-plugin-gnokii-9999/" #{package_mask_file}]
%x[sed -i.bak "s/=app-pda\\/libopensync-plugin-google-calendar-9999/#=app-pda\\/libopensync-plugin-google-calendar-9999/" #{package_mask_file}]
%x[sed -i.bak "s/=app-pda\\/libopensync-plugin-gpe-9999/#=app-pda\\/libopensync-plugin-gpe-9999/" #{package_mask_file}]
%x[sed -i.bak "s/=app-pda\\/libopensync-plugin-irmc-9999/#=app-pda\\/libopensync-plugin-irmc-9999/" #{package_mask_file}]
%x[sed -i.bak "s/=app-pda\\/libopensync-plugin-palm-9999/#=app-pda\\/libopensync-plugin-palm-9999/" #{package_mask_file}]
%x[sed -i.bak "s/=app-pda\\/libopensync-plugin-python-9999/#=app-pda\\/libopensync-plugin-python-9999/" #{package_mask_file}]
%x[sed -i.bak "s/=app-pda\\/libopensync-plugin-syncml-9999/#=app-pda\\/libopensync-plugin-syncml-9999/" #{package_mask_file}]
%x[sed -i.bak "s/=app-pda\\/libopensync-plugin-vformat-9999/#=app-pda\\/libopensync-plugin-vformat-9999/" #{package_mask_file}]
