#### Short term tasks
* ~~Script class~~
    + ~~**convert scripts to tasks; run unblocking tasks in parallel**~~
    + ~~**check dependant tables before filling current one**~~
    + ~~shared resources for workers~~
    + ~~log queries and stats~~
    + ~~add '-1' option for max_threads~~
* ~~database~~
    + ~~separate thread for queries that insert/update data~~
    + ~~**support insert/update via specified cached statement**~~
    + ~~threadsafe queue for data that is going to be inserted~~
* ~~Logger~~
    + ~~loggin in separate thread~~
    + ~~**possibility to log data in HRF in case of exception**~~
    + ~~grouplog API~~
* ~~parser~~
    * ~~**new parse method: simple and fast**~~
* scripts
    + **scripts to tasks migration**
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
    + rewrite using Python
    + replace calls of external apps with Python API calls:
        - env setup
        - versions compare
        - portageq
        - install/uninstall actions
        - split PF into category and version (current implementation fails for 'net-misc/cisco-vpnclient-3des')
* Script class
    + rename 'arch' to 'keyword', 'keyword' to keyword_status?
    + keep in mind that need to have easy way to debug specified item(s)
    + make logger (and database) module injectable into Script/Worker class
* database
    + [support overlays priority](https://www.linux.org.ru/forum/general/8364331?cid=8366484)
    + investigate joining keywords and masks into single entity
    + create some constraint/trigger/function to protect flags table of duplicate data [1^](https://www.linux.org.ru/forum/development/8077477), [2^](http://stackoverflow.com/questions/10231338/)
    + data deduplication
        - find a way do not make dups in ipackage_content.item
        - find a way to reuse license_spec records
        - find a way to reuse/inherit profile`s package.mask data
        - check what homepages are similar and report? them to devs
        - check what descriptions are similar and report? them to devs
    + check if using WAL accees mode will give some perf?
    + ```CREATE TABLE time_test (my_date timestamp)```
    + [strict types](http://stackoverflow.com/questions/2761563/sqlite-data-types)
    + separate connections (and statements?) for read/write __do we need this?__
    + issue with queries and specified params run from workers. __do we still have this?__
    + separate table for repos parent dir
    + move database code into separate application/process
* logger
    + ...
* scripts
    + add to tmp tables also a source_id on 1st stage, to make 2nd stage even more simple
    + get all expand use flags from make.conf
    + check scripts (\d\d_\w+\.check\.rb)
        - where to place
        - when to run
        - best format
    + ebuild licences: db, licences without deps, licences with logical 'or', conditional licences
    + find faster way of getting available EAPIs
* libraries
    + move all libraries into separate namespace
    + allow defining of deleted repos without hacks
* parser
    + do we need it?
* find out fastest location for portage tree

