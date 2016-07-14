#!/usr/bin/python
#
# This is a proof of concept (May 4, 2015)
#
# This script uses bibtexparser (https://bibtexparser.readthedocs.org/),
# installed by one of the methods
#   easy_install --user bibtexparser
#   pip install bibtexparser
#   apt-get install python-bibtexparser
#
# Usage: cat something.bib | ./bib2json.py
# Output on stdout.
#
# could also use `import fileinput` if it would not be linewise
#
# (CC0) 2015, 2016 SvenK

import sys
fhandle = sys.stdin

import bibtexparser
db = bibtexparser.load(fhandle)
entries_list = db.entries


import json

print json.dumps(entries_list)
