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

# new profiles folder
`mkdir -p profiles_v2`

# content of the new profiles folder
`cp profiles/* profiles_v2 2> /dev/null`

# base folder
`cp -r profiles/base profiles_v2/`

# join 2 base package.mask files
`cat profiles_v2/package.mask >> profiles_v2/base/package.mask`
# make one of them 'missed'
`mv profiles_v2/package.mask profiles_v2/package.mas_k`

# adding x86 arch
`cp -r profiles/arch/x86 profiles_v2/base`
# adding we do not care about xbox architecture for now
`rm -r profiles_v2/base/x86/xbox`

# adding amd64 arch
`mkdir -p profiles_v2/base/amd64`
# adding files for amd64 arch
`cp profiles/arch/amd64/* profiles_v2/base/amd64 2> /dev/null`

# adding linux platform for x86
`mkdir -p profiles_v2/base/x86/linux`
# adding linux platform for x86
`cp profiles/default/linux/* profiles_v2/base/x86/linux 2> /dev/null`

# adding linux platform for x86
`mkdir -p profiles_v2/base/amd64/linux`
# adding linux platform for amd64
`cp profiles/default/linux/* profiles_v2/base/amd64/linux 2> /dev/null`

# adding default feature
`mkdir -p profiles_v2/base/x86/linux/default`
# adding default feature
`mkdir -p profiles_v2/base/amd64/linux/default`

# adding files for default feature for x86
`echo 'sys-libs/uclibc' > profiles_v2/base/x86/linux/default/package.mask`
# adding files for default feature for amd64
`echo 'sys-libs/uclibc' > profiles_v2/base/amd64/linux/default/package.mask`

# adding subprofiles for x86
`cp -r profiles/default/linux/x86/* profiles_v2/base/x86/linux/default/ 2> /dev/null`
# adding subprofiles for amd64
`cp -r profiles/default/linux/amd64/* profiles_v2/base/amd64/linux/default/ 2> /dev/null`
