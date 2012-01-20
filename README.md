Portage
=======

Portage ([1](http://www.gentoo.org/doc/en/handbook/handbook-x86.xml?part=2&chap=1), [2](http://en.wikipedia.org/wiki/Portage_(software))) is a package management software for Gentoo Linux. It stores all data in plain txt files (I know about sqlite cache)

* I do not like when it takes minutes to do 'emerge -pvte world'
* Also there are dozen places where files that imply portage work are stored. I would like to see that number reduced

Possibly there are other things that I do not like in portage, but..

I am in process of learning how databases/sql works. To make this process more interesting I am trying to put portage tree (all of it) and related info into database.

For now its a pet project but if it will look solid and fast would be nice to have it as new PM in Gentoo


Installation
-----------

git clone at this moment


Requirements
-----

    Ruby 1.8 (compatibility with 1.9 has not been checked)
    http://rubygems.org/
    http://sqlite-ruby.rubyforge.org/
    http://nokogiri.org/


Testing
-------

Nothing really to test as for now


Contributing
------------

Want to contribute? Great!

1. Fork it.
2. Create a branch (`git checkout -b my_markup`)
3. Commit your changes (`git commit -am "Added Snarkdown"`)
4. Push to the branch (`git push origin my_markup`)
5. Create an [Issue][1] with a link to your branch
6. Enjoy a refreshing Diet Coke and wait
