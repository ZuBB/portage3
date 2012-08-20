#### Short term tasks
* ~~**ruby 1.9 with native threads**~~
* ~~**portage libs: one more refactoring**~~
* **early kill/end of db and logger threads**
* ~~deal with pathes~~
    + ~~find nice way to do includes for all kind of scripts~~
    + ~~"root_path" vs "root_folder" vs "portage_home"~~
    + ~~options["storage"]["root"] is not valid 'path'~~
* ~~database~~
    + ~~thread pool for queries that insert/update data~~
    + ~~common statement for queries that insert/update data~~
    + ~~on exception log only error mesage and values~~
    + ~~cache statements~~
    + ~~tables/colums naming~~
* ~~Script class~~
    + ~~use '$0' to get process name and get rid of 'script' param~~
    + ~~shared resources for workers~~
    + ~~evaluate injecting of :get_data and :process methods into Script/Worker~~
    + ~~pre/post insert tasks~~
    + ~~post processing checks~~
    + ~~log queries and stats~~
* profiles
    + `No such file or directory - /dev/shm/portage/profiles2/arch.list (Errno::ENOENT)`
    + find solution for use flags & profiles
* scripts
    + ~~wrong handling of homepages: ebuild may refer to 1+ homepage~~
    + ~~versions: script, compare method, ruby+python tools, verify scripts, check module~~
    + flags stuff: db, ~~module~~, ~~ebuilds~~, profiles, ~~make.conf~~, ~~users~~
    + dependancies: db, scripts
    + installed stuff: ~~db~~, ~~scripts~~
    + ~~after 'on end cleanup' will be implemented - merge *p1.rb and *p2.rb scripts~~
    + rework scripts that have size more than 2kB (constantly in background progress)
* setup scripts
    + ~~new script for getting data/setting/check available apps/props/pathes~~
    + calling script for all in theirs forlder
* Logger
    + ~~thread~~
    + ~~groulog API~~
    + ~~backup previous file~~
    + ~~close log device~~
    + before loggin db issue itself, need to log original(using HRF) data
* parser
    * **fast parse**
    * fix bugs
    * light improvement
* examples:
    + example(s) for use flags stuff
    + example(s) for dependancies
    + example(s) for installed stuff
    + statistics on what is in db
* installation
    * gemfile
    * setup instructions
* conditional (**if have free time**)
    + database
        - separate statements for read/write
        - issue with queries and specified params run from workers.
        - support insert via *specified* cached statement. __do we need this?__
    + Script class
        - keep in mind that need to have easy way to debug specified item(s)
        - make database and logger modules injectable into Script/Worker class
    + scripts
        - find faster way of getting available EAPIs

#### Long term tasks
* Python
    + select python sqlite wrapper (apsw vs pysqlite vs..)
    + rewrite using Python (start with things that are used for all scripts)
    + replace calls of external apps with Python API calls
        - env setup
        - versions
        - portageq
    + find calls for install/uninstall actions
* database
    + create some constraint/trigger/function to protect flags table of duplicate data [1^](https://www.linux.org.ru/forum/development/8077477), [2^](http://stackoverflow.com/questions/10231338/)

#### Blue-sky ideas
* profiles
* database
    + check if using WAL accees mode will give some perf?
    + ```CREATE TABLE time_test (my_date timestamp)```
    + separate table for repos parent dir
    + [strict types](http://stackoverflow.com/questions/2761563/sqlite-data-types)
* Script class
    + check dependant tables before filling current one
* put portage tree to the faster location

#### Useful links
* [znurt](http://znurt.org)
* [devmanual](http://devmanual.gentoo.org)
* http://dev.gentoo.org/~zmedico/portage/doc/portage.html
* http://blog.flameeyes.eu/2009/09/the-size-of-the-gentoo-tree
* http://blog.flameeyes.eu/2009/10/and-finally-the-portage-tree-overhead-data (protected with password for some reason), [copy in Google's cache](http://webcache.googleusercontent.com/search?q=cache:dZiCptS9UdwJ:blog.flameeyes.eu/2009/10/and-finally-the-portage-tree-overhead-data+&cd=1&hl=en&ct=clnk&client=ubuntu), [cc at gdrive](http://goo.gl/9JHh3)
* [some notes on portage and dbs](http://www.linux-archive.org/gentoo-alt/582446-rfc-changing-sys-apps-portage-python-api-use-eroot-instead-root-keys-portage-db-similar-map-objects.html)
* [portage on non Gentoo Linux distro](http://xanda.org/index.php?page=install-gentoo-portage-on-non-gentoo-distribution)
* http://www.computerra.ru/interactive/694037/ (russian)
* Database
    + http://habrahabr.ru/blogs/python/137677/
    + http://habrahabr.ru/blogs/programming/130617/
    + http://habrahabr.ru/blogs/development/111754/
    + http://habrahabr.ru/blogs/php/113872/
    + http://www.sqlite.org/c3ref/profile.html
    + http://stackoverflow.com/questions/3199790

#### Source code of some reworked PMs.
* git://git.debian.org/users/jak/apt2.git
* svn://anonsvn.gentoo.org/portage/main/trunk
* git://yum.baseurl.org/yum.git
* git://git.etoilebsd.net/pkgng

#### Misc
* /var/cache/edb/dep/usr/portage.sqlite
* man man |col -bx > /tmp/man.txt
* check all soft links in ```/etc``` folder
