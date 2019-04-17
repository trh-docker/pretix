#!/usr/bin/dumb-init /bin/sh
cd /opt/tlm/pretix/src 
make all

/usr/sbin/nginx &
/usr/local/bin/pretix /opt/tlm/data
