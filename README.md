Content
-------

1. <a href="#why">Why</a>
2. <a href="#requirements">Requirements</a>
3. <a href="#installation">Installation</a>
4. <a href="#setup">Setup</a>
5. <a href="#usage">Usage</a>
6. <a href="#status">Status</a>

Why
---

Portage ([1](http://www.gentoo.org/doc/en/handbook/handbook-x86.xml?part=2&chap=1), [2](http://en.wikipedia.org/wiki/Portage_(software\))\) is a package management software for Gentoo Linux.

Below there are some things that I do not like in portage

* [ **Speed** ] Gentoo is all about choice and speed. But its irritating when it takes minutes to do tasks that involves dependancy calculation (`emerge -pvte world` for example)
* [ **Data duplication** ] It stores all data in plain txt files. There is nothing bad in it. But some type of the data are duplicated couple of times.
* [ **Miss of app that does all but fast** ] There are couple of apps that do quite general tasks in terms of PM. None of them is not fast enough (except eix)
* [ **Current db structure does not help** ] There is a possibility to store portage cache in the sqlite database ([1], [2]). However this does not help portage work faster. Also I do not like [structure of the db](https://gist.github.com/4362786) (resides in `/var/cache/edb/dep/usr/portage.sqlite`) that is used

Possibly there are others..

To improve my knowledge of SQL I decided to make a try to put portage cache and some related data into [SQLite](http://en.wikipedia.org/wiki/SQLite) database.

[1] - [http://en.gentoo-wiki.com/wiki/Portage_SQLite_Cache](http://en.gentoo-wiki.com/wiki/Portage_SQLite_Cache)<br>
[2] - [http://optimization.hardlinux.ru/?page_id=152](http://optimization.hardlinux.ru/?page_id=152)(rus)

Requirements
-----

Next list of packages are mandatory
* Ruby 1.9
* SQLite
* rubygems
* libxml2
* libxslt

Next list of ruby gems are also mandatory
* sqlite-ruby
* nokogiri
* json

In Gentoo Linux you can use next commands to install all of them

```
emerge -vtNa =dev-lang/ruby-1.9* =dev-db/sqlite-3.7* dev-libs/libxml2 dev-libs/libxslt
gem install sqlite3 json nokogiri
```

**Note1**: `rubygems` should be also installed as dependancy for Ruby automatically.<br>
**Note2**: maybe you should take care about `ruby_targets` environment variable in `make.conf`

Installation
-----------

Most simple way to get it is to do a `git clone` operation
<pre>
git clone git@github.com:ZuBB/portage3.git [/path]
</pre>

Setup
-------

* go to `bin` dir in your favourite term app
* run `01_generate_config`. Follow onscreen insctructions
* run `02_prepare_fast_storage`. You might want to check script params before run
* run `03_fill_db`. You need to check script params before run

Now you have most important portage data in sqlite database

Usage
-------

Go to `example` dir and try to use tool(s) you like

Status
-------

* For now its a JFF project
* Currently its in experimental status (broken master, dozens of branches, stable API is nonsense, Friday's commits, etc.)
* Yes, I do have a [roadmap](https://github.com/ZuBB/portage3/blob/master/issues.md)! **Short term tasks** (means prototype is ready) is current milestone. No deadline is assigned. Next one is **Long term tasks** (means unschedulled)

