#
# Dumb DB wrapper
#
# Initial Author: Vasyl Zuzyak, 04/05/12
# Latest Modification: Vasyl Zuzyak, ...
#

class Portage3::Client
    def initialize(host, port, params)
        @socket = TCPSocket.open(host, port)
        @socket.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1)
        IO.select(nil, [@socket], nil, 360)

        if params.has_key?('id')
            @id = set_id(params['id'])
        else
            @id = set_id(Digest::MD5.hexdigest(Random.rand.to_s))
        end

    end

    def set_id(id = '')
        @id = id if id.is_a?(String) && id.size > 0
    end

    def put(*params)
        params_hash = create_hash(*params)
        @socket.puts(stringify(params_hash))
    end

    def get(*params)
        params_hash = create_hash(*params)
        params_hash['responce'] = true
        @socket.puts(stringify(params_hash))
        parse(@socket.gets)['result'] rescue nil
    end

    def get_and_close(*params)
        result = get(*params)
        close
        result
    end

    def put2(params)
		begin
			@socket.puts(stringify(params))
		rescue Exception => exception
			STDOUT.puts exception.message
		end
    end

    def get2(params)
		result = nil
		begin
			result = @socket.gets
		rescue Exception => exception
			STDOUT.puts exception.message
		end
		parse(result)['result'] if result
    end

    def close
        @socket.close
    end

    private
    def create_hash(param, *other_params)
        params = { 'action' => param }
        params['params'] = other_params unless other_params.empty?

        params
    end

    def stringify(params)
		begin
			JSON.generate(params)
		rescue Exception => exception
			STDOUT.puts exception.message
			nil
		end
    end

    def parse(string)
		begin
			JSON.parse(string)
		rescue Exception => exception
			STDOUT.puts exception.message
			STDOUT.puts string
			nil
		end
    end
end
