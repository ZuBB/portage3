Content
-------

1. <a href="#Why">Why</a>
2. <a href="#Requirements">Requirements</a>
3. <a href="#Installation">Installation</a>
4. <a href="#Setup">Setup</a>
5. <a href="#Testing">Testing</a>
6. <a href="#Contributing">Contributing</a>

Why
---

Portage ([1](http://www.gentoo.org/doc/en/handbook/handbook-x86.xml?part=2&chap=1), [2](http://en.wikipedia.org/wiki/Portage_(software\))) is a package management software for Gentoo Linux.


Below are some things that I do not like in portage

* It stores all data in plain txt files. Some things are duplicated couple of times.
There is a possibility to store portage cache in sqlite database ([1], [2]).
However I do not like structure of the [db](file:////var/cache/edb/dep/usr/portage.sqlite) that is used for that (one table with all stuff in it)
* Its irritating when it takes minutes to do 'emerge -pvte world'
* There are several places where files that related to the portage work are stored.
* Dozen(s) of apps/tools are written that do quite general tasks in terms of PM. None of thems is not fast enough except eix

Possibly there are others..

At some moment I decided to improve my knowledge of SQL. To make this process more interesting I am trying to put portage cache and some related data into [SQLite](http://en.wikipedia.org/wiki/SQLite) database.

For now its a JFF project but if it will look solid and fast, it would be nice to have it as addition to PM in Gentoo

[1] - [http://en.gentoo-wiki.com/wiki/Portage_SQLite_Cache](http://en.gentoo-wiki.com/wiki/Portage_SQLite_Cache)<br>
[2] - [http://optimization.hardlinux.ru/?page_id=152](http://optimization.hardlinux.ru/?page_id=152)(rus)

Requirements
-----

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

Installation
-----------

Currently AFAIK this tool is not available in any [Gentoo overlay](http://www.gentoo.org/proj/en/overlays/userguide.xml)

Due to this most simple way to try it is to do a `git clone` operation
<pre>
git clone git://github.com/zvasyl/portage3.git /opt/portage-next
</pre>

Setup
-------

**TBD**

Testing
-------

This is most interesting part for you :)

Take a look at files in *bin/examples* directory

Everything else **TBD**

Contributing
------------

[As usual](https://github.com/github/markup/#contributing-1)
