#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 02/06/12
# Latest Modification: Vasyl Zuzyak, ...
#
require 'envsetup'
require 'utils'

# hash with options
profiles_file = File.join(Utils.get_profiles2_home, 'profiles.desc')

%x[sed -i.bak "s/default\\/linux\\/amd64/amd64\\/linux\\/default/" #{profiles_file}]
%x[sed -i.bak "s/default\\/linux\\/x86/x86\\/linux\\/default/" #{profiles_file}]
