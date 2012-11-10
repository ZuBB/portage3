#### Short term tasks
* ~~Script class~~
    + ~~**convert scripts to tasks; run unblocking tasks in parallel**~~
    + ~~**check dependant tables before filling current one**~~
    + ~~shared resources for workers~~
    + ~~pre/post insert tasks~~
    + ~~post processing checks~~
    + ~~log queries and stats~~
    + ~~add '-1' option for max_threads~~
* ~~database~~
    + ~~separate thread for queries that insert/update data~~
    + ~~**support insert/update via specified cached statement**~~
    + ~~threadsafe queue for data that is going to be inserted~~
* ~~Logger~~
    + ~~loggin in separate thread~~
    + ~~backup previous file~~
    + ~~**possibility to log data in HRF in case of exception**~~
    + ~~grouplog API~~
* ~~parser~~
    * ~~**new parse method: simple and fast**~~
* scripts
    + **scripts to tasks migration**
    + ~~homepages: db, scripts, checks~~
    + ~~versions: script, compare method, ruby+python tools, verify scripts, check module~~
    + flags stuff: db, ~~module~~, ~~ebuilds~~, profiles, ~~make.conf~~, ~~users~~
    + dependancies: db, scripts
    + ~~installed stuff: db, scripts, 'missed' ebuilds~~, use flags
* setup scripts
    + ~~new script for getting data/setting/check available apps/props/pathes~~
    + ~~calling scripts for all in theirs forlder~~
    + new path of make.conf
* ~~deal with pathes~~
* examples
    + examples for use flags stuff, dependancies, installed stuff
    + statistics on what is in db
* readme

#### Long term tasks
* Python
    + select python sqlite wrapper (apsw vs pysqlite vs..)
    + rewrite using Python (start with things that are used for all scripts)
    + replace calls of external apps with Python API calls:
        - env setup
        - versions
        - portageq
        - install/uninstall actions
* Script class
    + keep in mind that need to have easy way to debug specified item(s)
    + make logger (and database) module injectable into Script/Worker class
    + create reusable 'modules' for case(s) like this: fill 'missed' categories
* database
    + [support overlays priority](https://www.linux.org.ru/forum/general/8364331?cid=8366484)
    + investigate joining keywords and masks into single entity
    + create some constraint/trigger/function to protect flags table of duplicate data [1^](https://www.linux.org.ru/forum/development/8077477), [2^](http://stackoverflow.com/questions/10231338/)
    + find a way to reuse license_spec records
    + find a way do not make dups in ipackage_content.item
    + check if using WAL accees mode will give some perf?
    + ```CREATE TABLE time_test (my_date timestamp)```
    + [strict types](http://stackoverflow.com/questions/2761563/sqlite-data-types)
    + separate connections (and statements?) for read/write __do we need this?__
    + issue with queries and specified params run from workers.
    + separate table for repos parent dir
* logger
    + ...
* scripts
    + get all expand use flags from make.conf
    + check scripts (\d\d_\w+\.check\.rb)
        - where to place
        - when to run
        - best format
    + ebuild licences: db, licences without deps, licences with logical 'or', conditional licences
    + find faster way of getting available EAPIs
    + check what homepages are similar and report? them to devs
    + check what descriptions are similar and report? them to devs
* libraries
    + allow defining of deleted repos without hacks
* parser
    + do we need it?
* find out fastest location for portage tree

