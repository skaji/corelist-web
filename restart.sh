#!/bin/bash

DIR=$( cd "$( dirname "$0" )" && pwd )
PERL_VERSION=5.18.0

if [ -f $DIR/from_*.pid ]; then
    kill `cat $DIR/from_*.pid`
    rm -f $DIR/from_*.pid
fi


cd /

export PATH=$DIR/local/bin:$HOME/.plenv/versions/$PERL_VERSION/bin:/usr/local/bin:/usr/bin:/bin
export PERL5LIB=$DIR/local/lib/perl5

now=`date +%Y-%m-%d_%H-%M-%S`
exec plackup                \
    --path /corelist        \
    --server Starman        \
    --daemonize             \
    --listen localhost:3333 \
    --pid $DIR/from_${now}.pid   \
    $DIR/app.psgi
