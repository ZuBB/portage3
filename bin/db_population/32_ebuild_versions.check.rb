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
        # TASK #1: no '0' at version_order position
        # TASK #2: max(version_order) can't be bigger than ebuilds per package
        # TASK #3: no duplicates of version_order per package
    end
end

