#!/usr/bin/python

import sys

try:
    import portage
except ImportError:
    print ""
    sys.exit(0)

pkg = sys.argv[1]
porttree = portage.db[portage.root]['porttree']
for atom in porttree.dbapi.cp_list(pkg):
    print(atom)
