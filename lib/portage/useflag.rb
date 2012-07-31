#
# Library supporting analytics scripts running on CloudDB
#
# Initial Author: Vasyl Zuzyak, 04/02/12
# Latest Modification: Vasyl Zuzyak, ...
#
class UseFlag
    ENTITY = self.name.downcase[0..-7]
    TYPES = ['hidden', 'expand', 'local', 'global']
    STATES = ['masked', 'disabled', 'enabled', 'forced']
    SQL = { 'type' => 'SELECT id FROM flag_types WHERE type=?' }
    REGEXPS = {
        'local'  => Regexp.new("([\\w\\/\\-\\+]+:)?([\\w\\+\\-]+)(?:\\s-\\s)(.*)"),
        'expand' => Regexp.new('([\\w\\+\\-]+)(?:\\s-\\s)(.*)'),
        'hidden' => Regexp.new('([\\w\\+\\-]+)(?:\\s-\\s)(.*)'),
        'global' => Regexp.new('([\\w\\+\\-]+)(?:\\s-\\s)(.*)'),
        'state' => Regexp.new('^[^\\w]?')
    }

    def self.get_flag(flag)
        flag.sub(REGEXPS['state'], '')
    end

    def self.get_flag_state(flag)
        # app-doc/pms section 8.2
        sign = REGEXPS['state'].match(flag).to_s
        case sign
        when '-' then 'disabled'
        when '+' then 'enabled'
        when '' then 'enabled'
        else nil
        end
    end
end

