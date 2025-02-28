#!/usr/bin/env bash

TEST_SUITE_FILE=$(dirname $0)/redis-values-suite.yaml
TMP_DIR=$(dirname $0)/tmp
mkdir -p $TMP_DIR

TMP_TEST_VALUE_INPUT=$TMP_DIR/__values__.yaml
TMP_TEMPLATE_OUTPUT=$TMP_DIR/__template_output__.yaml
TMP_EXTRACTED_MANIFEST=$TMP_DIR/__extracted_manifest__.yaml



# Function: redis-configmap-tests
# Inputs:
#   $1 - The path to the YAML file containing all Kubernetes manifests.
#   $2 - The path to the YAML file containing the input values.
function redis-configmap-tests() {
    local _all_manifests_file=$1
    local _input_file=$2

    local _selected_manifest_file=$(extract-manifest ConfigMap wandb-redis-configmap $_all_manifests_file)
    
    local _expected_port=$(get-expected-value $_input_file "redis.port")
    local _actual_port=$(yq ".data.REDIS_PORT" $_selected_manifest_file)
    expected-equal $_expected_port $_actual_port "wandb-redis-configmap REDIS_PORT"

    local _expected_host=$(get-expected-value $_input_file "redis.host")
    local _actual_host=$(yq ".data.REDIS_HOST" $_selected_manifest_file)
    expected-equal $_expected_host $_actual_host "wandb-redis-configmap REDIS_HOST"
}



function run_suite() {
  local _doc_lengths=$(yq eval 'length' $TEST_SUITE_FILE)
  local _idx=0

  for _size in $_doc_lengths; do 
    if [ $_size -ne 0 ]; then
          # echo "DEBUG: doc size $_size at $_idx"
          yq "select(document_index == $_idx)" $TEST_SUITE_FILE > $TMP_TEST_VALUE_INPUT

          echo "TEST CASE: $(yq '.testsuite.name' $TMP_TEST_VALUE_INPUT)"
                 
          helm template wandb $(dirname $0)/../charts/operator-wandb --values $TMP_TEST_VALUE_INPUT > $TMP_TEMPLATE_OUTPUT

          redis-configmap-tests $TMP_TEMPLATE_OUTPUT $TMP_TEST_VALUE_INPUT
      fi   
      _idx=$((_idx+1))
  done
}




#######################################################
## Testing Framework


# Function: find-manifest
# Description: This function finds the index of a specific Kubernetes manifest in a YAML file containing multiple manifests.
# 
# Inputs:
#   $1 - The kind of the Kubernetes resource (e.g., Pod, Service, Deployment).
#   $2 - The name of the Kubernetes resource.
#   $3 - The path to the YAML file containing the Kubernetes manifests.
#
# Output:
#   The filepath of the extracted matching manifest if found, otherwise it errors.
function extract-manifest() {
    local _kind=$1
    local _name=$2
    local _file=$3
    local _docidx=$(yq "select(.kind == \"$_kind\" and .metadata.name == \"$_name\") | document_index" $_file)
    if [ -z "$_docidx" ]; then
        echo "ERROR: Could not find manifest of kind $_kind with name $_name in file $_file"
        exit 1
    fi
    local _extracted_file="$TMP_DIR/__extracted_manifest_${_kind}_${_name}__.yaml"
    yq "select(.kind == \"$_kind\" and .metadata.name == \"$_name\")" $_file > $_extracted_file
    echo $_extracted_file
}

function get-manifest-value() {
    local _input_file=$1
    local _key=$2
    local _result=$(yq ".metadata.labels.${_key}" $_input_file)
    if [ -z "$_result" ]; then
        echo "ERROR: Could not find manifest value in file $_input_file"
        exit 1
    fi
    echo $_result
}

function get-expected-value() {
    local _input_file=$1
    local _key=$2
    local _result=$(yq ".testsuite.expected.${_key}" $_input_file)
    if [ -z "$_result" ]; then
        echo "ERROR: Could not find expected value in file $_input_file"
        exit 1
    fi
    echo $_result
}

function expected-equal() {
    local _expected=$1
    local _actual=$2
    local _name=$3
    echo "expect $_name -- $_expected == $_actual"
    if [ "$_expected" != "$_actual" ]; then
        echo "ERROR: Expected $_expected but got $_actual"
    fi
}



run_suite
