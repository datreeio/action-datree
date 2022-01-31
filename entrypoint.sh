#!/bin/sh -l

inputfile="$INPUT_FILE"
options="$INPUT_OPTIONS"
token="$INPUT_TOKEN"

if [ -z "$DATREE_TOKEN" ]; then
    if [ -z "$token" ]; then
        echo "No token configured, see https://github.com/datreeio/action-datree for instructions"
        exit 1
    else
        DATREE_TOKEN="$token"
    fi
fi

curl https://get.datree.io | /bin/bash
datree test $inputfile $options