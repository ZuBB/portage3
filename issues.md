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
    + ~~evaluate injecting of `get_data` and `process` methods into Script/Worker~~
    + ~~pre/post insert tasks~~
    + ~~post processing checks~~
    + ~~log queries and stats~~
    + ~~add '-1' option for max_threads~~
* profiles
    + `No such file or directory - /dev/shm/portage/profiles2/arch.list (Errno::ENOENT)`
    + find solution for use flags & profiles
* scripts
    + ~~homepages: db, scripts, checks~~
    + ~~versions: script, compare method, ruby+python tools, verify scripts, check module~~
    + ebuild licences: ~~licences without deps~~, licences with logical or, conditional licences
    + flags stuff: db, ~~module~~, ~~ebuilds~~, profiles, ~~make.conf~~, ~~users~~
    + dependancies: db, scripts
    + ~~installed stuff: db, scripts, 'missed' ebuilds~~
* setup scripts
    + ~~new script for getting data/setting/check available apps/props/pathes~~
    + ~~calling scripts for all in theirs forlder~~
    + get all expand use flags from make.conf
    + new path of make.conf
* Logger
    + ~~thread~~
    + ~~grouplog API~~
    + ~~backup previous file~~
    + ~~close log device~~
    + before loggin db issue itself, need to log original(using HRF) data
* parser
    * ~~**new parse method: simple and fast**~~
* examples:
    + examples for use flags stuff, dependancies, installed stuff
    + statistics on what is in db
* installation
    * setup instructions
    * gemfile

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
    + investigate joining keywords and masks into single entity
    + create some constraint/trigger/function to protect flags table of duplicate data [1^](https://www.linux.org.ru/forum/development/8077477), [2^](http://stackoverflow.com/questions/10231338/)
    + find a way to reuse license_spec records
    + find a way do not make dups in ipackage_content.item
    + check if using WAL accees mode will give some perf?
    + ```CREATE TABLE time_test (my_date timestamp)```
    + separate table for repos parent dir
    + [strict types](http://stackoverflow.com/questions/2761563/sqlite-data-types)
    + separate statements for read/write
    + issue with queries and specified params run from workers.
    + support insert via *specified* cached statement. __do we need this?__
* Script class
    + convert scripts to tasks; runt unblocking tasks in parallel. etc
    + split tasks into parts (for scripts like *_pN.rb). Parts may be threaded or not
    + check dependant tables before filling current one
    + keep in mind that need to have easy way to debug specified item(s)
    + make database and logger modules injectable into Script/Worker class
	+ create reusable 'modules' for case like next: fill missed categories 
* libraries
    + allow defining of deleted repos without hacks
* scripts
    + find faster way of getting available EAPIs
    + check what homepages are similar and report? them to devs
    + check what descriptions are similar and report? them to devs
* parser
    + do we need it?
* put portage tree to the faster location

