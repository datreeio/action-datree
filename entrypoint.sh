#!/bin/sh -l
set -ex

inputpath="$INPUT_PATH"
cliArguments="$INPUT_CLIARGUMENTS"
isHelmChart="$INPUT_ISHELMCHART"
helmArgs="$INPUT_HELMARGUMENTS"

if [ -z "$DATREE_TOKEN" ]; then
    echo "No account token configured, see https://github.com/datreeio/action-datree for instructions"
    exit 1
fi

curl https://get.datree.io | /bin/bash

if [ "$isHelmChart" == "true" ]; then
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | /bin/bash
    helm plugin install https://github.com/datreeio/helm-datree
    
    helm datree test $inputpath $cliArguments -- $helmArgs
else
    datree test $inputpath $cliArguments  
fi
