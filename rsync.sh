#/bin/sh
#
# This rsync script was used over the years with a number of different options,
# sometimes from the system hosting the mirror to the system hosting the live
# system, sometimes the other way around (as today).
#
# (CC0) 2010-2016 SvenK

# This is not supposed for CGI usage
[ $REQUEST_URI ] && echo -e "Content-Type: text/plain\n\nNo CGI script" && exit

# change to directory of script (nice for cron usage, etc.)
cd `dirname $0`

# Slashes: in order to copy directory contents, make sure the trailing
# slash is at the SOURCE only.

# really make sure the target folder != .
# otherwise --delete will wipe out this script and anything else
TARGET='sven@svenk.org:/home/sven/sko/UniOrdner'

# source at ITP
SOURCE='/home/koeppel/UniOrdner/'


# The target charset on this machine (source is utf-8, omit if we
# are using UTF-8)
#CHARSET='--iconv="ISO_8859-15"'
CHARSET=''

# today this is over ssh
rsync -az --delete --stats --log-file='rsync.log' ${CHARSET} ${SOURCE} ${TARGET}

# afterwards make some log output
##echo "This is the syncer running on $(hostname) at $(date)" > mirror.txt
##echo -n "Last sync: `date -R`" >> mirror.txt

# and another output
##date -R | cat footer.html.template - > footer.html

# this was it.
