#### Short term tasks
* rewrite using Python (start with things that are used for all scripts)
* deal with pathes
    + find nice way to do includes for all kind of scripts
    + "root_path" vs "root_folder" vs "portage_home"
    + options["storage"]["root"] is not valid 'path'
* database
    + select python sqlite wrapper (code.google.com/p/apsw as example)
    + check if using WAL accees mode for sqlite will give some perf?
    + thread pool for queries that insert/update data
    + make database module injectable into Script/Worker class
    + common statement for queries that insert/update data
    + on exception log only error mesage and values
* Script class
    + use '$0' to get process name and get rid of 'script' param
    + include database and logger modules
    + shared resources for workers
    + pre/post processing hooks
    + evaluate injecting of :get_data and :process methods into Script/Worker
    + keep in mind that need to have easy way to debug specified item(s)
* 'tables population' scripts
    + script #32. package conky
    + new modules/classes for portage objects
    + integrate code from 'list_package_ebuilds.py' into versions scripts
* setup scripts
    + new script for getting data/setting/check available apps/props/pathes
    + calling script for all in theirs forlder
* Logger
    + create log file on first log attempt
    + before loggin issue itself, need to log source of the issue

#### Long term tasks
* use flags stuff: scripts + example
* dependancies: scripts + example
* installed stuff: scripts + example
* improve parser
* check dependant tables before filling current one
* put portage tree to the faster location
* separate table for repos parent dir
* CREATE TABLE time_test (my_date timestamp)
* /var/cache/edb/dep/usr/portage.sqlite
* profiles

#### Useful links
* [znurt](http://znurt.org)
* [devmanual](http://devmanual.gentoo.org)
* http://dev.gentoo.org/~zmedico/portage/doc/portage.html
* http://blog.flameeyes.eu/2009/09/the-size-of-the-gentoo-tree
* http://blog.flameeyes.eu/2009/10/and-finally-the-portage-tree-overhead-data (protected with password for some reason), [copy in Google's cache](http://webcache.googleusercontent.com/search?q=cache:dZiCptS9UdwJ:blog.flameeyes.eu/2009/10/and-finally-the-portage-tree-overhead-data+&cd=1&hl=en&ct=clnk&client=ubuntu), [cc at gdrive](http://goo.gl/9JHh3)
* [some notes on portage and dbs](http://www.linux-archive.org/gentoo-alt/582446-rfc-changing-sys-apps-portage-python-api-use-eroot-instead-root-keys-portage-db-similar-map-objects.html)
* [portage on non Gentoo Linux distro](http://xanda.org/index.php?page=install-gentoo-portage-on-non-gentoo-distribution)

#### Source code of some reworked PMs.
* git://git.debian.org/users/jak/apt2.git
* svn://anonsvn.gentoo.org/portage/main/trunk
* git://yum.baseurl.org/yum.git
* git://git.etoilebsd.net/pkgng

#### Misc
<pre>
make.globals -> ../usr/share/portage/config/make.globals  
make.profile -> ../usr/portage/profiles/default/linux/x86/10.0
</pre>
