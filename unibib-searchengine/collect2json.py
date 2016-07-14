#!/usr/bin/python
# Python2
#
# merged from bib2json.py and bibcollect.sh, a pure Python implementation
#
# (CC0) 2015 SvenK

# bibtexparser: https://bibtexparser.readthedocs.io/
# this is the reason why we use Python here.
import bibtexparser
import json
from os import path
from subprocess import Popen, PIPE
import re

unibase = "/home/sven/sko/UniOrdner"
uniurl = "http://svenk.org/uni"

def rewrite_xxYYYY(text):
	return re.sub(r'.*([WS]S) ([0-9]*)[^/]*(/.*)', lambda mo: mo.group(1).lower()+mo.group(2)+mo.group(3), text)

def collect2json():
	out = []

	# modern python...
	proc = Popen(["./locate.sh", "uni.bib"], stdout=PIPE)

	for line in proc.stdout:
		bibfname = line.strip()
		# compute some path names from bibfname
		relfname = '/'+rewrite_xxYYYY(path.relpath(bibfname, unibase))
		reldir = rewrite_xxYYYY(path.dirname(relfname))

		with open(bibfname, 'r') as fhandle:
			db = bibtexparser.load(fhandle)
			entries_list = db.entries
			for e in entries_list:
				e['bibfile'] = uniurl + relfname
				e['bibdir'] = uniurl + reldir
				e['thumb_from'] = '1' # pdf thumbnailing system

				# standarize entry:
				# fix some paths which are supposed to be valid URLs
				pathkeys = ['sources', 'slides']
				for key in pathkeys:
					if key in e: # prefix e[key] with bibdir
						e[key] = uniurl+reldir+('/' if e[key][0] != '/' else '')+e[key]

				# make sure keywords are separated. The bibtexparser does weird
				# things with the keyword field (renames it, for example)
				keywords_search = ['keyword', 'keywords']
				keywords_target_key = 'keywords'
				for key in keywords_search:
					if key in e and type(e[key]) != list:
						if keywords_target_key in e:
							e[keywords_target_key] += re.split('\W+', e[key])
						else:
							e[keywords_target_key] = re.split('\W+', e[key])
			
			out += entries_list

	print json.dumps(out)

if __name__ == "__main__":
	collect2json()
