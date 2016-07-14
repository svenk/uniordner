#!/bin/bash
#
# bibcollect is the bash workhorse in the unibib-searchengine system.
# It uses the external programs bibclean (https://www.ctan.org/pkg/bibclean)
# and parallel (https://www.gnu.org/software/parallel/), both available
# in standard linux distributions or easily installable in ~/bin.
#
# This is a quite efficient script which uses the locatedb to cleanup and compile
# all the bibtex files collected from the huge uniordner directory structure (5GB).
# These are O(100) bibtex files, and the runtime is below 1sec.
#
# (CC0) 2015 SvenK
#

# without trailing slash
UniBase="/home/sven/sko/UniOrdner"
export UniBase

# decide about the format. This works but is deactivated since
# the pythonic bib2json shall be invoked directly.
format="bibtex"
options='jbh'
while getopts $options option
do case $option in
	j )	format="json";;
	b )	format="bibtex";;
	h )	echo "Usage: $0 [-j] [-b] [-h]"
		echo " -j: Give out json"
		echo " -b: Give out bibtex (default)"
		echo " -h: Print this help"
		exit 0;;
	\? )	if (( (err & ERROPTS) != ERROPTS ))
		then
			echo "error: $NOEXIT $ERROPTS Unknown option."
			exit 0
		fi;;
esac; done;
export format

# Infos
if [[ $format == "bibtex" ]]; then
	echo "#* UniOrdner Bibfile collector, (c) 2015 SK" >&2
	echo "#* Running at $(date)" >&2
fi

process_bibfile() {
	bibFile="$1"

	if [[ $format == "bibtex" ]]; then
		# BIBTEX format.
		# here we cannot easily insert own variables
		echo "#* Bibtex file: $bibRel"
		echo
		bibclean --no-fix-names "$bibFile"
		echo # newline
	else
		# JSON format
		# here we can easily insert own variables
		bibRel=$(dirname "${bibFile#$UniBase}")
		bibFilename=$(basename "$bibFile")
		# rewrite to xxYYYY links
		bibShortRel=$(echo "$bibRel" | sed 's/.*\([WS]S\) \([0-9]*\)[^/]*\(\/.*\)/\/\L\1\E\2\3/' )
		# test outputs:
		#echo "bibRel: $bibRel";	echo "bibFilename: $bibFilename"; echo "bibShortRel: $bibShortRel"
		export bibRel; export bibFilename; export bibShortRel;
		# run the converter on each bibfile.
		## this does not (yet) include the env files. see the pure python implementation instead
		cat "$bibFile" | ./bib2json.py

	fi
	# pending: for each bibitem -> xxYYYY path reinschreiben!


}

export -f process_bibfile

./locate.sh uni.bib | parallel process_bibfile 
