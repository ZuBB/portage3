#
# Dumb DB wrapper
#
# Initial Author: Vasyl Zuzyak, 04/05/12
# Latest Modification: Vasyl Zuzyak, ...
#

require 'socket'

require 'rubygems'
require 'json'

class Portage3::Client
    def initialize(host, port)
        @socket = TCPSocket.open(host, port)
        @socket.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1)
    end

    def put(params)
        @socket.puts(stringify(params))
    end

    def get(params)
        @socket.puts(stringify(params))
        parse(@socket.gets)['result']
    end

    def put_and_close(params)
        put(params)
        close
    end

    def get_and_close(params)
        result = get(params)
        close
        result
    end

    def close
        @socket.close
    end

    private
    def stringify(params)
        JSON.generate(params)
    end

    def parse(string)
        JSON.parse(string)
    end
end
