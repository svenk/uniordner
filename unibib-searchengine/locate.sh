#!/bin/sh
# use the locate database
exec locate -d $(dirname $0)/locate.db $@
