#
# Library supporting analytics scripts running on CloudDB
#
# Initial Author: Vasyl Zuzyak, 04/02/12
# Latest Modification: Vasyl Zuzyak, ...
#

class Mask
    STATES = ['masked', 'unmasked']
    SQL = {
        '@' => 'SELECT state, id FROM mask_states;'
    }

    def self.get_mast_state(str)
        # take care about leading '-'
        # it means this atom/package should treated as unmasked
        str == '-' ? STATES[1] : STATES[0]
    end
end

