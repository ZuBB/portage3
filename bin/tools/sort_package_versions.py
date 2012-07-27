#!/usr/bin/python

import sys

try:
    import sqlite3
    from portage.versions import *
except ImportError:
    print ""
    sys.exit(0)

if len(sys.argv) == 1:
    print 'Error: pass package id or package name!'
    sys.exit(0)

versions = []
separator = ', '
filename = '/dev/shm/test-20120724-221542.sqlite'
package_id_sql = 'select version from ebuilds where package_id=?'
package_sql = """
select version
from ebuilds e
join packages p on p.id=e.package_id
where package=?"""

conn = sqlite3.connect(filename)
cur = conn.cursor()

if sys.argv[1].isdigit():
    cur.execute(package_id_sql, (int(sys.argv[1]), ))
else:
    cur.execute(package_sql, (sys.argv[1], ))

for row in cur:
    versions.append(row[0])

print separator.join(sorted(versions, cmp=vercmp))
conn.close()

