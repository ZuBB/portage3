###### Mandatory

Next list of packages are mandatory
* Ruby
* SQLite
* rubygems

Next list of ruby gems are also mandatory
* [sqlite-ruby](http://sqlite-ruby.rubyforge.org/)
* [json](http://json-jruby.rubyforge.org/)
* [nokogiri](http://nokogiri.org/)

In Gentoo Linux you can use next commans to install them

```
emerge -vta =dev-lang/ruby-1.9* =dev-db/sqlite-3.7*
gem install sqlite3 json nokogiri
```

**Note1**: `rubygems` should be also installed as dependancy for Ruby (automatically).<br>
**Note2**: maybe you should take care about `ruby_targets` environment variable in `make.conf`

###### Optional

There is also optional dependancies. Usually you should not need them unless you are doing some develoment/hacking

```
    >dev-python/pysqlite-2.6
    >=app-portage/eix-0.25.5
```

