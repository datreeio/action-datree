#!/bin/bash

set -x

inputpath="$INPUT_PATH"
cliArguments="$INPUT_CLIARGUMENTS"
outputFile="$INPUT_OUTPUTFILE"
isHelmChart="$INPUT_ISHELMCHART"
helmArgs="$INPUT_HELMARGUMENTS"
isKustomization="$INPUT_ISKUSTOMIZATION"
kustomizeArgs="$INPUT_KUSTOMIZEARGUMENTS"

echo "TESTTTT: $cliArguments"

printf "datree version: "
datree version
printf "\n"

# enable recursive globbing (to support **/*.yaml for instance)
shopt -s globstar

if [ -z "$DATREE_TOKEN" ]; then
  printf "No account token configured, see https://github.com/datreeio/action-datree for instructions\n"
  exit 1
fi

EXIT_STATUS=0
EXIT_STATUS_REPORT=0

function create_report() {
  EXIT_STATUS_REPORT="$?"

  # Github step summary
  RESULT_JSON_PATH="$HOME/.datree/lastPolicyCheck.json"
  if [ ! -f "$RESULT_JSON_PATH" ]; then
    echo ""
    echo "No report lastPolicyCheck.json found!"
    return
  fi

  PASSED_YAML=$(jq .evaluationSummary.passedYamlValidationCount "$RESULT_JSON_PATH")
  PASSED_K8S=$(jq .evaluationSummary.k8sValidation "$RESULT_JSON_PATH" | awk -F[\"/] '{print $2}')
  PASSED_POLICY=$(jq .evaluationSummary.passedPolicyValidationCount "$RESULT_JSON_PATH")
  POLICY_NAME=$(jq .policySummary.policyName "$RESULT_JSON_PATH" | awk -F[\"\"] '{print $2}')
  TOTAL_RULES=$(jq .policySummary.totalRulesInPolicy "$RESULT_JSON_PATH")
  CONFIGS_COUNT=$(jq .evaluationSummary.configsCount "$RESULT_JSON_PATH")
  FILES_COUNT=$(jq .evaluationSummary.filesCount "$RESULT_JSON_PATH")
  PASSED=$(jq .policySummary.totalPassedCount "$RESULT_JSON_PATH")
  FAILED_RULES=$(jq .policySummary.totalRulesFailed "$RESULT_JSON_PATH")
  SKIPPED=$(jq .policySummary.totalSkippedRules "$RESULT_JSON_PATH")
  FAILED_SCHEMA=$(jq ".k8sValidationResults | length" "$RESULT_JSON_PATH")
  FAILED_YAML=$(jq ".yamlValidationResults | length" "$RESULT_JSON_PATH")

  echo "<img src=\"https://raw.githubusercontent.com/datreeio/datree/main/images/datree_logo_color.svg\" width=\"350\"/>&nbsp;" >>"$GITHUB_STEP_SUMMARY"
  echo "" >>"$GITHUB_STEP_SUMMARY"
  echo "☸️ Want guardrails on your cluster as well? Try out our [admission webhook!](https://github.com/datreeio/admission-webhook-datree#datree-admission-webhook) ☸️&nbsp;  " >>"$GITHUB_STEP_SUMMARY"
  echo "## Datree policy check results" >>"$GITHUB_STEP_SUMMARY"
  echo "**Source path:** ${1}" >>"$GITHUB_STEP_SUMMARY"
  if [[ -n "$POLICY_NAME" ]]; then 
    echo "**Policy name:** "$POLICY_NAME"" >>"$GITHUB_STEP_SUMMARY"
  fi
  echo "" >>"$GITHUB_STEP_SUMMARY"
  echo "**Passed YAML validation:** ${PASSED_YAML}/${FILES_COUNT}" >>"$GITHUB_STEP_SUMMARY"
  echo "**Passed Kubernetes schema validation:** ${PASSED_K8S}/${FILES_COUNT}" >>"$GITHUB_STEP_SUMMARY"
  echo "**Passed policy check:** ${PASSED_POLICY}/${FILES_COUNT}" >>"$GITHUB_STEP_SUMMARY"
  
  if [[ -n "$POLICY_NAME" ]]; then
    echo "| ✹✹ | ✹✹ |" >>"$GITHUB_STEP_SUMMARY"
    echo "|---|---|" >>"$GITHUB_STEP_SUMMARY"
    echo "| **Enabled rules in policy** | <div align=\"center\">**${TOTAL_RULES}**</div> |" >>"$GITHUB_STEP_SUMMARY"
    echo "| **Configs tested against policy** | <div align=\"center\">**${CONFIGS_COUNT}**</div> |" >>"$GITHUB_STEP_SUMMARY"
    echo "| **Total rules evaluated** | <div align=\"center\">**$((TOTAL_RULES * FILES_COUNT))**</div> |" >>"$GITHUB_STEP_SUMMARY"
    echo "| **Total rules skipped** | <div align=\"center\">**${SKIPPED}**</div> |" >>"$GITHUB_STEP_SUMMARY"
    echo "| **Total rules failed** ⛔ | <div align=\"center\">**${FAILED_RULES}**</div> |" >>"$GITHUB_STEP_SUMMARY"
    echo "| **Total rules passed** ✅ | <div align=\"center\">**${PASSED}**</div> |" >>"$GITHUB_STEP_SUMMARY"
    echo "| **See all rules in policy** | <div align=\"center\">**[https://app.datree.io](https://app.datree.io)**</div> |" >>"$GITHUB_STEP_SUMMARY"
    echo "" >>"$GITHUB_STEP_SUMMARY"
    echo "" >>"$GITHUB_STEP_SUMMARY"
  fi

  if [[ $FAILED_YAML -eq 0 && $FAILED_SCHEMA -eq 0 && $FAILED_RULES -eq 0 ]]; then
    echo "### 🥳 All validations passed successfully! 🥳" >>"$GITHUB_STEP_SUMMARY"
    return
  fi

  if [[ $FAILED_SCHEMA -gt 0 ]]; then
    echo "### Schema validation errors:" >> "$GITHUB_STEP_SUMMARY"
    for ((i = 0; i < "$FAILED_SCHEMA"; i++)); do
      FILENAME=$(jq ".k8sValidationResults[$i].path" "$RESULT_JSON_PATH")
      echo "**>> Filename: $FILENAME**" >> "$GITHUB_STEP_SUMMARY"
      for ((j = 0; j < $(jq ".k8sValidationResults[$i].errors | length" "$RESULT_JSON_PATH"); j++)); do
        ERROR=$(jq ".k8sValidationResults[$i].errors[$j].ErrorMessage" "$RESULT_JSON_PATH")
        echo "❌ k8s schema validation error: $ERROR" >> "$GITHUB_STEP_SUMMARY"
      done
    done

    echo "" >>"$GITHUB_STEP_SUMMARY"
    echo "" >>"$GITHUB_STEP_SUMMARY"
  fi

  if [[ $FAILED_RULES -gt 0 ]]; then
    echo "### Failed rules:" >>"$GITHUB_STEP_SUMMARY"
    echo "" >>"$GITHUB_STEP_SUMMARY"
  fi

  NUM_OF_TESTED_FILES=$(jq ".policyValidationResults | length" "$RESULT_JSON_PATH")
  INDEX=0
  while [[ $INDEX -lt $NUM_OF_TESTED_FILES ]]; do
    FILENAME=$(jq ".policyValidationResults[$INDEX] | .fileName" "$RESULT_JSON_PATH")
    echo "**>> Filename: ${FILENAME}**" >>"$GITHUB_STEP_SUMMARY"
    echo "" >>"$GITHUB_STEP_SUMMARY"

    FAILED_IN_FILE=$(jq ".policyValidationResults[$INDEX] | .ruleResults | length" "$RESULT_JSON_PATH")
    for ((i = 0; i < "$FAILED_IN_FILE"; i++)); do
      IS_SKIPPED=$(jq ".policyValidationResults[0] | .ruleResults[$i] | .occurrencesDetails[0] | .isSkipped" "$RESULT_JSON_PATH")
      if [[ $IS_SKIPPED == "true" ]]; then
        continue
      fi

      VIOLATED_RULE_ID=$(jq ".policyValidationResults[$INDEX] | .ruleResults[$i] | .identifier" "$RESULT_JSON_PATH")
      VIOLATED_RULE_NAME=$(jq ".policyValidationResults[$INDEX] | .ruleResults[$i] | .name" "$RESULT_JSON_PATH")
      VIOLATED_RULE_OCCURRENCES=$(jq ".policyValidationResults[$INDEX] | .ruleResults[$i] | .occurrencesDetails | length" "$RESULT_JSON_PATH")
      VIOLATED_RULE_FAIL_MESSAGE=$(jq ".policyValidationResults[$INDEX] | .ruleResults[$i] | .messageOnFailure" "$RESULT_JSON_PATH")

      echo "❌ **$VIOLATED_RULE_NAME [$VIOLATED_RULE_OCCURRENCES occurrence/s]**" >>"$GITHUB_STEP_SUMMARY"
      for ((j = 0; j < "$VIOLATED_RULE_OCCURRENCES"; j++)); do
        VIOLATED_RULE_METADATA_NAME=$(jq ".policyValidationResults[0] | .ruleResults[$i] | .occurrencesDetails[$j] | .metadataName" "$RESULT_JSON_PATH")
        VIOLATED_RULE_KIND=$(jq ".policyValidationResults[0] | .ruleResults[$i] | .occurrencesDetails[$j] | .kind" "$RESULT_JSON_PATH")
        echo "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;metadata.name: $VIOLATED_RULE_METADATA_NAME (kind: $VIOLATED_RULE_KIND)" >>"$GITHUB_STEP_SUMMARY"

        VIOLATED_RULE_SCHEMA_PATH=$(jq ".policyValidationResults[0] | .ruleResults[$i] | .occurrencesDetails[$j] | .failureLocations[0] | .schemaPath" "$RESULT_JSON_PATH")
        VIOLATED_RULE_LINE=$(jq ".policyValidationResults[0] | .ruleResults[$i] | .occurrencesDetails[$j] | .failureLocations[0] | .failedErrorLine" "$RESULT_JSON_PATH")
        VIOLATED_RULE_COLUMN=$(jq ".policyValidationResults[0] | .ruleResults[$i] | .occurrencesDetails[$j] | .failureLocations[0] | .failedErrorColumn" "$RESULT_JSON_PATH")
        echo "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;\> key: $VIOLATED_RULE_SCHEMA_PATH (line: $VIOLATED_RULE_LINE:$VIOLATED_RULE_COLUMN)" >> $GITHUB_STEP_SUMMARY
      done
      echo "💡 $VIOLATED_RULE_FAIL_MESSAGE  " >>"$GITHUB_STEP_SUMMARY"
      echo "" >>"$GITHUB_STEP_SUMMARY"
      echo "---" >>"$GITHUB_STEP_SUMMARY"
    done

    echo "" >>"$GITHUB_STEP_SUMMARY"

    ((INDEX = INDEX + 1))
  done
}

if [ "$isHelmChart" = "true" ]; then
  while read -r helmchart; do
    dir="$(dirname "$helmchart")"
    chart_type=`cat $helmchart|grep "type:"|cut -d' ' -f 2`
    if [ "$chart_type" != "library" ]; then
      echo "*** Proceeding to test Helm chart: $helmchart ***"
      set +e
      helm datree test "$dir" $cliArguments -- $helmArgs
      create_report "$dir"
      set -e
      if [ "$EXIT_STATUS_REPORT" -gt "$EXIT_STATUS" ]; then
        EXIT_STATUS="$EXIT_STATUS_REPORT"
      fi
      echo ""
    else 
      echo "skipping check on $helmchart as it is of type library"
    fi
  done < <(find "$inputpath" -type f -name 'Chart.y*ml')
elif [ "$isKustomization" = "true" ]; then
  datree kustomize test $inputpath $cliArguments -- $kustomizeArgs
  create_report "$inputpath"
else
  if [[ "$cliArguments" == *"sarif"* ]]; then
    datree test $inputpath $cliArguments > "$HOME"/output.sarif
    ls -al "$HOME"
  else
    datree test $inputpath $cliArguments
  fi
  create_report "$inputpath"
fi

if [ "$EXIT_STATUS_REPORT" -gt "$EXIT_STATUS" ]; then
  EXIT_STATUS="$EXIT_STATUS_REPORT"
fi

exit $EXIT_STATUS
