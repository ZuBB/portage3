#
# A bit extended standart logger module
#
# Initial Author: Vasyl Zuzyak, 04/10/12
# Latest Modification: Vasyl Zuzyak, ...
#

require 'socket'
require 'rubygems'
require 'json'

module Portage3::Server
    def process_connection(connection)
        strings2process = []
        IO.select([connection], nil, nil, 30)
        connection.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1)

        while income_str = connection.gets
            next if /^\s*$/ =~ income_str
            strings2process.concat(Portage3::Server.split_string(income_str))

            while strings2process.size > 0
                process_string(connection, strings2process.shift)
            end
        end
    end

    def process_string(connection, processed_str)
        begin
            json_object = JSON.parse(processed_str)
        rescue
            if @logger
                @logger.error('Failed to parse next incoming string')
                @logger.info(processed_str)
            else
                STDOUT.puts 'Failed to parse next incoming string'
                STDOUT.puts processed_str
            end
            return
        end

        unless json_object.has_key?('action')
            if @logger
                @logger.error("incoming object does not have 'action' param")
                @logger.info(processed_str)
            else
                STDOUT.puts "incoming object does not have 'action' param"
                STDOUT.puts processed_str
            end
            return
        end

        result = send(json_object['action'], *json_object['params'])

        if json_object['responce']
            connection.puts(JSON.generate({'result' => result}))
        end

        message = json_object['params'][0]['data'].first rescue nil # db
        message ||= json_object['params'][0][1] rescue nil # log

        if message == self.class::EOS
            @processing_thread.join
            connection.close
            Process.exit(true)
        end
    end

    def self.split_string(income_string)
        income_string.split(/\}\s*\{/).map { |str|
            str = '{' + str unless /^\s*\{/ =~ str
            str = str + '}' unless /\}\s*$/ =~ str
            str
        }
    end
end
