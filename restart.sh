#!/bin/sh

if [ -f from_*.pid ]; then
    kill `cat from_*.pid`
    rm -f from_*.pid
fi

now=`date +%Y-%m-%d_%H-%M-%S`

exec carton exec plackup    \
    --path /corelist        \
    --server Starman        \
    --daemonize             \
    --listen localhost:3333 \
    --pid from_${now}.pid   \
    app.psgi
