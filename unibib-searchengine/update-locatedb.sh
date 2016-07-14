#!/bin/bash
#
# Update the locate database. It will contain
# all the UniOrdner things.
# An initial run takes around 10secs, while an update
# only takes around 2secs.
# This is faster than any `find` command could run.
#

set -e
cd $(dirname $0)
updatedb -l 0 -o locate.db -U ../..
