#!/usr/bin/dumb-init /bin/sh
pre=$1
cd /opt/tlm/pretix/src 
make production
# sudo -u pretixuser make production
/usr/local/bin/pretix ${pre} &
sudo -u root /usr/sbin/nginx 
