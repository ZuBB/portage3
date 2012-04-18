#!/usr/bin/python

import sys,portage
pkg = sys.argv[1]
porttree = portage.db[portage.root]['porttree']
for atom in porttree.dbapi.cp_list(pkg):
	print(atom)

