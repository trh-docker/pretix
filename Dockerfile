FROM quay.io/spivegin/tlmbasedebian:latest as source
WORKDIR /opt/tlm/
RUN apt-get update && apt-get install -y git &&\
    apt-get autoclean && apt-get autoremove &&\
    rm -rf /tmp/* /var/lib/apt/lists/* /var/tmp/*
RUN git clone https://github.com/pretix/pretix.git


FROM quay.io/spivegin/tlmpython:latest
WORKDIR /opt/tlm/
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    default-libmysqlclient-dev \
    gettext \
    git \
    libffi-dev \
    libjpeg-dev \
    libmemcached-dev \
    libpq-dev \
    libssl-dev \
    libxml2-dev \
    libxslt1-dev \
    locales \
    nginx \
    python-dev \
    python-virtualenv \
    python3-dev \
    sudo \
    supervisor \
    zlib1g-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    dpkg-reconfigure locales && \
    locale-gen C.UTF-8 && \
    /usr/sbin/update-locale LANG=C.UTF-8 && \
    mkdir /etc/pretix && \
    mkdir /data && \
    useradd -ms /bin/bash -d /pretix -u 15371 pretixuser && \
    echo 'pretixuser ALL=(ALL) NOPASSWD: /usr/bin/supervisord' >> /etc/sudoers && \
    mkdir /static

ENV LC_ALL=C.UTF-8 \
    DJANGO_SETTINGS_MODULE=production_settings
RUN mkdir -p /opt/tlm/pretix/src && chown -R pretixuser:pretixuser /opt/tlm
# To copy only the requirements files needed to install from PIP
COPY --from=source /opt/tlm/pretix/src/requirements /opt/tlm/pretix/src/requirements
COPY --from=source /opt/tlm/pretix/src/requirements.txt /opt/tlm/pretix/src
RUN pip3 install -U \
    pip \
    setuptools \
    wheel && \
    cd /pretix/src && \
    pip3 install \
    -r requirements.txt \
    -r requirements/memcached.txt \
    -r requirements/mysql.txt \
    -r requirements/redis.txt \
    gunicorn && \
    rm -rf ~/.cache/pip
COPY --from=source /opt/tlm/pretix/deployment/docker/pretix.bash /usr/local/bin/pretix
COPY --from=source /opt/tlm/pretix/deployment/docker/supervisord.conf /etc/supervisord.conf
COPY --from=source /opt/tlm/pretix/deployment/docker/nginx.conf /etc/nginx/nginx.conf
COPY --from=source /opt/tlm/pretix/deployment/docker/production_settings.py /opt/tlm/pretix/src/production_settings.py
COPY --from=source /opt/tlm/pretix/src /opt/tlm/pretix/src

RUN chmod +x /usr/local/bin/pretix && \
    rm /etc/nginx/sites-enabled/default && \
    cd /opt/tlm/pretix/src && \
    rm -f pretix.cfg && \
    mkdir -p data && \
    chown -R pretixuser:pretixuser /opt/tlm/pretix /data data && \
    sudo -u pretixuser make production

USER pretixuser
VOLUME ["/etc/pretix", "/data"]
EXPOSE 80
ENTRYPOINT ["pretix"]
CMD ["all"]