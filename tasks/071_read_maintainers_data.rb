#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/11/12
# Latest Modification: Vasyl Zuzyak, 01/11/12
#

klass = Class.new(Tasks::Runner) do
    self::DEPENDS = '041_packages'
    self::SQL = {
        'insert' => <<-SQL
            INSERT INTO tmp_package_maintainers
            (package_id, email, name, role)
            VALUES (?, ?, ?, ?);
        SQL
    }

    def get_data(params)
        Package.list_packages(params)
    end

    def process_item(params)
        persons = []
        package_id = params.delete_at(0);
        metadata_file = File.join(*params, 'metadata.xml')

        # https://bugs.gentoo.org/show_bug.cgi?id=566112
        unless File.exist?(metadata_file)
          @logger.error("Something is wrong with next package '#{File.join(*params)}'")
          return
        end

        Nokogiri::XML(IO.read(metadata_file)).xpath("//maintainer").each { |node|
            email = node.xpath('email').inner_text rescue ''
            name  = node.xpath('name').inner_text  rescue ''
            role  = node.xpath('description').inner_text rescue ''

            unless role.empty?
                role = role.split(',')[0]
                role = role.split('.')[0]
            end

            next if email.empty? || 'maintainer-needed@gentoo.org' == email

            persons << [package_id, email, name, role]
        }

        persons.each { |person|
            send_data4insert({'data' => [person]})
        }
    end
end

Tasks.create_task(__FILE__, klass)

