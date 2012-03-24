#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/11/12
# Latest Modification: Vasyl Zuzyak, 01/11/12
#
$:.push File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'rubygems'
require 'fileutils'
require 'optparse'
require 'tools'

# hash with options
options = Hash.new.merge!(OPTIONS)
portage_home = get_full_tree_path(options)
FileUtils.cd(portage_home)

# https://bugs.gentoo.org/show_bug.cgi?id=409337
`sed -i.bak1 -e '12,13d' ./sys-infiniband/libcxgb3/libcxgb3-1.2.5.ebuild`
`sed -i.bak1 -e '13,14d' ./sys-infiniband/libehca/libehca-1.2.2.ebuild`

# https://bugs.gentoo.org/show_bug.cgi?id=...
`sed -i.bak1 's/nls php debug doc nls/nls php debug doc/' ./app-emulation/libguestfs/libguestfs-1.8.16.ebuild`
