#!/bin/bash
export BUTLER_REPO="dp2_prep"
export SCOPE="dp2_prep"
export COLLECTION="TEMPLATE_COLLECTION"
export SITE="TEMPLATE_SITE"
export PIPELINE_RUN_TICKET="TEMPLATE_TICKET"
export TEST_NAME="register_rescue"
export TIMESTAMP=$((`date +%s` % 10000))
export TRANSFER_LIST_YAML="https://raw.githubusercontent.com/lsst-dm/datasettype_transfer_lists/refs/heads/main/cm_transfer_list.yaml"

rucio whoami

cat <<EOF >rucio_register.cfg
rucio_rse: "${SITE}_BUTLER_DISK"
scope: "${SCOPE}"
rse_root: TEMPLATE_RSE_ROOT
dtn_url: TEMPLATE_DTN_URL
EOF

export DATASET_PREFIX="Dataset/LSSTCam/runs/${BUTLER_REPO}/w_2026_35/${PIPELINE_RUN_TICKET}"
export DATASET="${DATASET_PREFIX}-rescue-${SITE}-2026Q3-00000001"
export CONFIG_FILE="rucio_register.cfg"
echo "Time: $(date +%s.%N) - Starting rucio-register rescue for $TEST_NAME $PIPELINE_RUN_TICKET at $SITE"

mkdir -p uuids

rucio-register dataset-list \
--repo "$BUTLER_REPO" \
--rucio-dataset "$DATASET" \
--rucio-register-config "$CONFIG_FILE" \
--uuidlist uuids/auto-register-failures.json \
--log-level DEBUG \
--chunk-size 500 \
--max-retries 8

result1=$?
echo "Time: $(date +%s.%N) - Finished rucio-register rescue for $TEST_NAME $PIPELINE_RUN_TICKET at $SITE "

echo $result1
if [ "$result1" != "0" ]; then
    echo "rucio-register rescue $TEST_NAME Failed"
    exit 1
else
    echo "rucio-register rescue $TEST_NAME Succeeded"
fi

echo "End Time: $(date +%s.%N)"
exit 0
