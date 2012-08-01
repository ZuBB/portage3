#!/usr/bin/python

import sys

try:
    import sqlite3
    from portage.versions import *
except ImportError:
    print ""
    sys.exit(0)

if len(sys.argv) == 1:
    print 'Error: required parameter is missing!'
    sys.exit(0)

versions = []
if len(sys.argv) == 2:
    versions = sys.argv[1].split(',')
else:
    conn = sqlite3.connect(sys.argv[1])
    cur = conn.cursor()

    package_id_sql = 'select version from ebuilds where package_id=?'
    package_sql = """
    select version
    from ebuilds e
    join packages p on p.id=e.package_id
    join categories c on c.id=p.category_id
    where category_name=? and package_name=?"""

    if sys.argv[2].isdigit():
        cur.execute(package_id_sql, (int(sys.argv[2]), ))
    else:
        params = sys.argv[2].split('/')
        cur.execute(package_sql, (params[0], params[1], ))

    for row in cur:
        versions.append(row[0])

    conn.close()

print ', '.join(sorted(versions, cmp=vercmp))

