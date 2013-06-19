#!/bin/sh

if [ -f from_*.pid ]; then
    kill `cat from_*.pid`
    rm -f from_*.pid
fi

DIR=`/usr/bin/perl -MCwd -MFile::Basename -e 'print dirname Cwd::abs_path shift' $0`

now=`date +%Y-%m-%d_%H-%M-%S`

export PATH=$DIR/local/bin:$PATH
export PERL5LIB=$DIR/local/lib/perl5

exec plackup  \
    --path /corelist        \
    --server Starman        \
    --daemonize             \
    --listen localhost:3333 \
    --pid from_${now}.pid   \
    app.psgi
