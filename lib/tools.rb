# Library supporting analytics scripts running on CloudDB
#
# Copyright(c) 2011 by Appcelerator, Inc. All Rights Reserved.
# This is proprietary software. Do not redistribute without express
# written permission.
#
# Initial Author: Vasyl Zuzyak, 12/12/11
# Latest Modification: Ronen Botzer, 12/15/11
#
require 'rubygems'
require 'json' unless Object.const_defined?(:JSON)

STORAGE = {
    :home_folder => 'portage3_data',
    :portage_home => 'portage',
    :required_space => 700,
    :root => '/dev/shm'
}

def some_stub_func()
    # do nothing
end

