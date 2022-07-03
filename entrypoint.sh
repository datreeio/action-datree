#!/bin/bash

inputpath="$INPUT_PATH"
cliArguments="$INPUT_CLIARGUMENTS"
isHelmChart="$INPUT_ISHELMCHART"
helmArgs="$INPUT_HELMARGUMENTS"
isKustomization="$INPUT_ISKUSTOMIZATION"
kustomizeArgs="$INPUT_KUSTOMIZEARGUMENTS"

printf "datree version: "
datree version
printf "\n"

# enable recursive globbing (to support **/*.yaml for instance)
shopt -s globstar

if [ -z "$DATREE_TOKEN" ]; then
    printf "No account token configured, see https://github.com/datreeio/action-datree for instructions\n"
    exit 1
fi

if [ "$isHelmChart" = "true" ]; then
    helm datree test $inputpath $cliArguments -- $helmArgs
elif [ "$isKustomization" = "true" ]; then
    datree kustomize test $inputpath $cliArguments -- $kustomizeArgs
else
    datree test $inputpath $cliArguments  
fi
