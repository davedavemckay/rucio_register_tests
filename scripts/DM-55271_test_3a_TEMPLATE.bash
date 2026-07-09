#!/bin/bash
export BUTLER_REPO="dp2_prep"
export SCOPE="dp2_prep"
export COLLECTION="TEMPLATE_COLLECTION"
export SITE="TEMPLATE_SITE"
export PIPELINE_RUN_TICKET="TEMPLATE_TICKET"
export TEST_NAME="DM-55271-test_3a"
export TIMESTAMP=$((`date +%s` % 10000))

rucio whoami

cat <<EOF >rucio_register.cfg
rucio_rse: "${SITE}_BUTLER_DISK"
scope: "${SCOPE}"
rse_root: TEMPLATE_RSE_ROOT
dtn_url: TEMPLATE_DTN_URL
EOF

export DATASET="Dataset/LSSTCam/runs/${BUTLER_REPO}/w_2026_23/${PIPELINE_RUN_TICKET}/${SITE}/${TEST_NAME}/${TIMESTAMP}"
export CONFIG_FILE="rucio_register.cfg"
echo "Time: $(date +%s.%N) - Starting rucio-register for $TEST_NAME $PIPELINE_RUN_TICKET at $SITE"

# use first 20 dataset types from the butler query-dataset-types command for the given collection
# butler query-dataset-types "$BUTLER_REPO" --collections "$COLLECTION" | tail -n +3 | head -n 20 | while IFS= read -r TYPE; do
#     echo "type $TYPE"

rucio-register auto-register \
--root-chain "$COLLECTION" \
--repo "$BUTLER_REPO" \
--rucio-register-config "$CONFIG_FILE" \
--log-level INFO \
--max-dataset-types 20 \
--max-workers 10

result1=$?
echo "Time: $(date +%s.%N) - Finished rucio-register auto-register --dryrun for $TEST_NAME $PIPELINE_RUN_TICKET at $SITE "

echo $result1
if [ "$result1" != "0" ]; then
    echo "rucio-register $TEST_NAME Failed"
else
    echo "rucio-register $TEST_NAME Succeeded"
fi

echo "End Time: $(date +%s.%N)"

exit 0