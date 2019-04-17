#!/usr/bin/dumb-init /bin/sh

/usr/local/bin/pretix webworker &
sleep 5
/usr/local/bin/pretix taskworker &
/usr/sbin/nginx