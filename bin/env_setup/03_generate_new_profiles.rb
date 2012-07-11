#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/27/12
# Latest Modification: Vasyl Zuzyak, ...
#
require 'envsetup'
require 'utils'

# hash with options
settings = Hash.new.merge!(Utils.get_settings)
# change dir to `home of the new portage data`
Dir.chdir(Utils.get_tree_home(settings))
profiles2_dir = settings['new_profiles']

# new profiles folder
`mkdir -p #{profiles2_dir}`

# content of the new profiles folder
`cp profiles/* #{profiles2_dir} 2> /dev/null`

# base folder
`cp -r profiles/base #{profiles2_dir}/`

# join 2 base package.mask files
`cat #{profiles2_dir}/package.mask >> #{profiles2_dir}/base/package.mask`
# make one of them 'missed'
`mv #{profiles2_dir}/package.mask #{profiles2_dir}/package.mas_k`

# adding x86 arch
`cp -r profiles/arch/x86 #{profiles2_dir}/base`
# adding we do not care about xbox architecture for now
`rm -r #{profiles2_dir}/base/x86/xbox`

# adding amd64 arch
`mkdir -p #{profiles2_dir}/base/amd64`
# adding files for amd64 arch
`cp profiles/arch/amd64/* #{profiles2_dir}/base/amd64 2> /dev/null`

# adding linux platform for x86
`mkdir -p #{profiles2_dir}/base/x86/linux`
# adding linux platform for x86
`cp profiles/default/linux/* #{profiles2_dir}/base/x86/linux 2> /dev/null`

# adding linux platform for x86
`mkdir -p #{profiles2_dir}/base/amd64/linux`
# adding linux platform for amd64
`cp profiles/default/linux/* #{profiles2_dir}/base/amd64/linux 2> /dev/null`

# adding default feature
`mkdir -p #{profiles2_dir}/base/x86/linux/default`
# adding default feature
`mkdir -p #{profiles2_dir}/base/amd64/linux/default`

# adding files for default feature for x86
`echo 'sys-libs/uclibc' > #{profiles2_dir}/base/x86/linux/default/package.mask`
# adding files for default feature for amd64
`echo 'sys-libs/uclibc' > #{profiles2_dir}/base/amd64/linux/default/package.mask`

# adding subprofiles for x86
`cp -r profiles/default/linux/x86/* #{profiles2_dir}/base/x86/linux/default/ 2> /dev/null`
# adding subprofiles for amd64
`cp -r profiles/default/linux/amd64/* #{profiles2_dir}/base/amd64/linux/default/ 2> /dev/null`

# folder with expand use flags
`cp -r profiles/desc -t #{profiles2_dir}/`
