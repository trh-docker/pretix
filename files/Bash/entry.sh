#!/usr/bin/dumb-init /bin/sh
cd /opt/tlm/pretix/src 
make production
# sudo -u pretixuser make production
/usr/local/bin/pretix /opt/tlm/data &
sudo -u root /usr/sbin/nginx 