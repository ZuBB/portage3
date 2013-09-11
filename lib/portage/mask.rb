#
# Library supporting analytics scripts running on CloudDB
#
# Initial Author: Vasyl Zuzyak, 04/02/12
# Latest Modification: Vasyl Zuzyak, ...
#

class Portage3::Mask
    STATES = ['masked', 'unmasked']
    SQL = {
        '@' => 'SELECT state, id FROM mask_states;'
    }

    def self.get_mast_state(str)
        # take care about leading '-'
        # it means this atom/package should treated as unmasked
        return (str.nil? || str.empty?) ? STATES[0] : STATES[1]
        return str.include?('-') ? STATES[1] : STATES[0]
    end
end

