#!/bin/sh -l

inputfile="$INPUT_FILE"
options="$INPUT_OPTIONS"
token=""

if [ -n "$INPUT_TOKEN" ]; then
    token="$INPUT_TOKEN"
elif [ -n "$DATREE_TOKEN" ]; then
    token="$DATREE_TOKEN"
else
    echo "No account token configured, see https://github.com/datreeio/action-datree for instructions"
    exit 1
fi

curl https://get.datree.io | /bin/bash
datree config set token "$token"
datree test $inputfile $options
