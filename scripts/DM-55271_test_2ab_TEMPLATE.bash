#!/bin/bash
export BUTLER_REPO="dp2_prep"
export SCOPE="dp2_prep"
export COLLECTION="TEMPLATE_COLLECTION"
export SITE="TEMPLATE_SITE"
export PIPELINE_RUN_TICKET="TEMPLATE_TICKET"
export TEST_NAME="DM-55271-test_2ab"

rucio whoami

cat <<EOF >rucio_register.cfg
rucio_rse: "${SITE}_BUTLER_DISK"
scope: "${SCOPE}"
rse_root: TEMPLATE_RSE_ROOT
dtn_url: TEMPLATE_DTN_URL
EOF

export DATASET="Dataset/LSSTCam/runs/${BUTLER_REPO}/w_2026_23/${PIPELINE_RUN_TICKET}/${SITE}/${TEST_NAME}"
export CONFIG_FILE="rucio_register.cfg"
echo "Time: $(date +%s.%N) - Starting rucio-register for $TEST_NAME $PIPELINE_RUN_TICKET at $SITE"

# use first 20 dataset types from the butler query-dataset-types command for the given collection
# butler query-dataset-types "$BUTLER_REPO" --collections "$COLLECTION" | tail -n +3 | head -n 20 | while IFS= read -r TYPE; do
#     echo "type $TYPE"

rucio-register auto-register \
--root-chain "$COLLECTION" \
--repo "$BUTLER_REPO" \
--dry-run \
--rucio-register-config "$CONFIG_FILE" \
--log-level DEBUG \
--max-dataset-types 2 \
--out-dir "uuids" \

    #


    # rucio-register data-products \
    # --repo "$BUTLER_REPO" \
    # --dataset-type "$TYPE" \
    # --collections "$COLLECTION" \
    # --rucio-dataset "$DATASET" \
    # --rucio-register-config "$CONFIG_FILE" \
    # --log-level DEBUG \
    # --chunk-size 30

# done
result1=$?
echo "Time: $(date +%s.%N) - Finished rucio-register auto-register --dryrun for $TEST_NAME $PIPELINE_RUN_TICKET at $SITE "

echo $result1
if [ "$result1" != "0" ]; then
    echo "rucio-register $TEST_NAME Failed"
else
    echo "rucio-register $TEST_NAME Succeeded"
fi

find uuids/ -type f -exec head {} \;

# head -n 10 "$first_uuid_file"

# find ./uuids -type f -print0 | xargs -0 -I {} -n 1 -P 10 bash -c 'rucio-register data-products \
# --repo "$BUTLER_REPO" \
# --dataset-type "$TYPE" \
# --collections "$COLLECTION" \
# --rucio-dataset {}'

exit 0