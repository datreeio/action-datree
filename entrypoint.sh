#!/bin/sh -l

inputfile="$INPUT_FILE"
options="$INPUT_OPTIONS"

if [ -z "$DATREE_TOKEN" ]; then
    echo "No account token configured, see https://github.com/datreeio/action-datree for instructions"
    exit 1
fi

curl https://get.datree.io | /bin/bash

datree test $inputfile $options