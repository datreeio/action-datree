#!/bin/sh

inputpath="$INPUT_PATH"
cliArguments="$INPUT_CLIARGUMENTS"
isHelmChart="$INPUT_ISHELMCHART"
helmArgs="$INPUT_HELMARGUMENTS"
isKustomization="$INPUT_ISKUSTOMIZATION"
kustomizeArgs="$INPUT_KUSTOMIZEARGUMENTS"


if [ -z "$DATREE_TOKEN" ]; then
    echo "No account token configured, see https://github.com/datreeio/action-datree for instructions"
    exit 1
fi

if [ "$isHelmChart" = "true" ]; then
    helm datree test $inputpath $cliArguments -- $helmArgs
elif [ "$isKustomization" = "true" ]; then
    datree kustomize test $inputpath $cliArguments -- $kustomizeArgs
    
else
    datree test $inputpath $cliArguments  
fi
