FROM quay.io/spivegin/caddy_only AS caddy-source

FROM quay.io/spivegin/tlmbasedebian:latest as source
WORKDIR /opt/tlm/
RUN apt-get update && apt-get install -y git &&\
    apt-get autoclean && apt-get autoremove &&\
    rm -rf /tmp/* /var/lib/apt/lists/* /var/tmp/*
RUN git clone https://github.com/pretix/pretix.git


FROM quay.io/spivegin/pretixbase:latest
WORKDIR /opt/tlm/
# Setting up Caddy Server, AFZ Cert and installing dumb-init
ENV DINIT=1.2.2 \
    DOMAIN=goconnectx.live \
    LC_ALL=C.UTF-8 \
    DJANGO_SETTINGS_MODULE=production_settings \
    PRETIX_CONFIG_FILE=/opt/tlm/pretix.cfg \
    INSTANCE_NAME=goconnectx.live


ADD https://raw.githubusercontent.com/adbegon/pub/master/AdfreeZoneSSL.crt /usr/local/share/ca-certificates/
ADD https://github.com/Yelp/dumb-init/releases/download/v${DINIT}/dumb-init_${DINIT}_amd64.deb /tmp/dumb-init_amd64.deb
COPY --from=caddy-source /opt/bin/caddy /opt/bin/
ADD files/Caddy/Caddyfile /opt/caddy/

RUN update-ca-certificates --verbose &&\
    chmod +x /opt/bin/caddy &&\
    ln -s /opt/bin/caddy /bin/caddy &&\
    dpkg -i /tmp/dumb-init_amd64.deb && \
    mkdir -p /opt/bin /opt/caddy &&\
    apt-get autoclean && apt-get autoremove

RUN mkdir -p /opt/tlm/pretix/src && chown -R pretixuser:pretixuser /opt/tlm
# To copy only the requirements files needed to install from PIP
COPY --from=source /opt/tlm/pretix/src/requirements /opt/tlm/pretix/src/requirements
COPY --from=source /opt/tlm/pretix/src/requirements.txt /opt/tlm/pretix/src
RUN pip3 install -U \
    pip \
    setuptools \
    wheel && \
    cd /opt/tlm/pretix/src && \
    pip3 install \
    -r requirements.txt \
    -r requirements/memcached.txt \
    -r requirements/mysql.txt \
    -r requirements/redis.txt \
    gunicorn && \
    rm -rf ~/.cache/pip
COPY files/pretix/pretix.bash /usr/local/bin/pretix
COPY files/pretix/supervisord.conf /etc/supervisord.conf
# COPY files/pretix/nginx.conf /etc/nginx/nginx.conf
COPY files/pretix/production_settings.py /opt/tlm/pretix/src/production_settings.py
COPY --from=source /opt/tlm/pretix/src /opt/tlm/pretix/src
ADD files/Bash/entry.sh /opt/bin
ADD files/pretix/pretix.cfg /opt/tlm/
RUN chmod +x /usr/local/bin/pretix && \
    rm /etc/nginx/sites-enabled/default && \
    chmod +x /opt/bin/entry.sh &&\
    cd /opt/tlm/pretix/src && \
    rm -f pretix.cfg && \
    mkdir -p data && \
    chown -R pretixuser:pretixuser /opt/tlm
    

USER pretixuser
VOLUME ["/etc/pretix", "/opt/tlm/data"]
EXPOSE 80 8080
ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD ["/opt/bin/entry.sh"]