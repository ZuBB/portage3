#
# Library supporting analytics scripts running on CloudDB
#
# Initial Author: Vasyl Zuzyak, 04/02/12
# Latest Modification: Vasyl Zuzyak, ...
#
require 'dbobject'

class UseFlag
    include DBobject

    ENTITY = self.name.downcase[0..-7]
    PROP_SUFFIXES = ['name', 'description', 'type_id']
    TYPES = ['global', 'local', 'expand', 'hidden']
    SQL = { 'type' => 'SELECT id FROM flag_types WHERE type=?' }
    STATES = ['masked', 'disabled', 'enabled', 'forced']
    Regexps = {
        'local'  => Regexp.new("([\\w\\/\\-\\+]+:)?([\\w\\+\\-]+)(?:\\s-\\s)(.*)"),
        'expand' => Regexp.new('([\\w\\+\\-]+)(?:\\s-\\s)(.*)'),
        'hidden' => Regexp.new('([\\w\\+\\-]+)(?:\\s-\\s)(.*)'),
        'global' => Regexp.new('([\\w\\+\\-]+)(?:\\s-\\s)(.*)')
    }
end

