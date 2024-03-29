#!/bin/bash
cd /opt/tlm/pretix/src
export DJANGO_SETTINGS_MODULE=production_settings
export DATA_DIR=/opt/tlm/data/
export HOME=/opt/tlm/pretix
export NUM_WORKERS=$((2 * $(nproc --all)))

if [ ! -d /opt/tlm/data/logs ]; then
    mkdir /opt/tlm/data/logs;
fi
if [ ! -d /opt/tlm/data/media ]; then
    mkdir /opt/tlm/data/media;
fi

if [ "$1" == "cron" ]; then
    exec python3 -m pretix runperiodic
fi

python3 -m pretix migrate --noinput

if [ "$1" == "all" ]; then
    exec sudo /usr/bin/supervisord -n -c /etc/supervisord.conf
fi

if [ "$1" == "webworker" ]; then
    exec gunicorn pretix.wsgi \
        --name pretix \
        --workers $NUM_WORKERS \
        --max-requests 1200 \
        --max-requests-jitter 50 \
        --log-level=info \
        --bind=unix:/tmp/pretix.sock
fi

if [ "$1" == "taskworker" ]; then
    export C_FORCE_ROOT=True
    exec celery -A pretix.celery_app worker -l info
fi

if [ "$1" == "shell" ]; then
    exec python3 -m pretix shell
fi

if [ "$1" == "upgrade" ]; then
    exec python3 -m pretix updatestyles
fi

echo "Specify argument: all|cron|webworker|taskworker|shell|upgrade"
exit 1
