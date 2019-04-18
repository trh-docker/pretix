#!/usr/bin/dumb-init /bin/sh
cd /opt/tlm/pretix/src 
make production
# sudo -u pretixuser make production
/usr/local/bin/pretix ${pre} &
# sudo -u root /usr/sbin/nginx 
sudo -u root caddy -conf /opt/caddy/Caddyfile
