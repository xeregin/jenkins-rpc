#!/bin/bash

if [[ $1 == "" || $2 == "" ]]; then
    echo "Expected usage: $0 <config_file> <IP_mod>"
    exit
fi

if [[ `stat $1 | sed '/stdin/d' 2> /dev/null` ]]; then
    echo "Config File found! Continuing..."
else
    echo "Could not find config file ( $1 )! Terminating..."
    exit
fi

cat $1 | sed "s/\([0-9]*\.[0-9]*\.[0-9]*\.[0-9]*[:]*[0-9]*\)/\1%$2/"
