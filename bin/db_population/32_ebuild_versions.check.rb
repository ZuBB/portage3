#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/04/12
# Latest Modification: Vasyl Zuzyak, 01/06/12
#
class Script
    def post_insert_check
        EbuildVersion.post_insert_check(MAIN_CHECK)
    end
end

