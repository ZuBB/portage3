Why
---

Portage ([1](http://www.gentoo.org/doc/en/handbook/handbook-x86.xml?part=2&chap=1), [2](http://en.wikipedia.org/wiki/Portage_(software\))) is a package management software for Gentoo Linux.


Below are some things that I do not like in portage

* It stores all data in plain txt files. Some things are duplicated couple of times.
There is a possibility to store portage cache in sqlite database ([1], [2]).
However I do not like its db structure that is being used for that)
* Its irritating when it takes minutes to do 'emerge -pvte world'
* There are several places where files that related to the portage work are stored.
* Dozen(s) of apps/tools are written that do quite general tasks in terms of PM. None of thems is not fast enough except eix

Possibly there are others..

At some moment I decided to improve my knowledge of SQL. To make this process more interesting I am trying to put portage cache and some related data into [SQLite](http://en.wikipedia.org/wiki/SQLite) database.

For now its a JFF project but if it will look solid and fast, it would be nice to have it as addition to PM in Gentoo

[1] - [http://en.gentoo-wiki.com/wiki/Portage_SQLite_Cache](http://en.gentoo-wiki.com/wiki/Portage_SQLite_Cache)<br>
[2] - [http://optimization.hardlinux.ru/?page_id=152](http://optimization.hardlinux.ru/?page_id=152)(rus)
