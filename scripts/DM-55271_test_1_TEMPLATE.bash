#!/bin/bash
export BUTLER_REPO="dp2_prep"
export SCOPE="dp2_prep"
export COLLECTION="TEMPLATE_COLLECTION"
export SITE="TEMPLATE_SITE"
export PIPELINE_RUN_TICKET="TEMPLATE_TICKET"
export TEST_NAME="DM-55271-test_1"
export TIMESTAMP=$((`date +%s` % 10000))

rucio whoami

cat <<EOF >rucio_register.cfg
rucio_rse: ${SITE}_BUTLER_DISK
scope: ${SCOPE}
rse_root: TEMPLATE_RSE_ROOT
dtn_url: TEMPLATE_DTN_URL
EOF

export DATASET="Dataset/LSSTCam/runs/${BUTLER_REPO}/w_2026_23/${PIPELINE_RUN_TICKET}/${SITE}/${TEST_NAME}/${TIMESTAMP}"
export CONFIG_FILE="rucio_register.cfg"
echo "Time: $(date +%s.%N) - Starting rucio-register for $TEST_NAME $PIPELINE_RUN_TICKET at $SITE"

# use first 10 dataset types from the butler query-dataset-types command for the given collection
butler query-dataset-types "$BUTLER_REPO" --collections "$COLLECTION" | tail -n +3 | awk '{print $1}' | head -n 4 | while IFS= read -r TYPE; do
    echo "type <${TYPE}>" # in braces to highlight any leading/trailing whitespace

    rucio-register data-products \
    --repo "$BUTLER_REPO" \
    --dataset-type "$TYPE" \
    --collections "$COLLECTION" \
    --rucio-dataset "$DATASET" \
    --rucio-register-config "$CONFIG_FILE" \
    --log-level DEBUG \
    --chunk-size 30

    result1=$?
    echo "Time: $(date +%s.%N) - Finished rucio-register for dataset_type $TYPE for $TEST_NAME $PIPELINE_RUN_TICKET at $SITE "

    echo $result1
    if [ "$result1" != "0" ]; then
        echo "rucio-register $TYPE $TEST_NAME failed"
    else
        echo "rucio-register $TYPE $TEST_NAME succeeded"
    fi
done

rucio content list --files ${SCOPE}:${DATASET} | grep -v "+-" | grep -v "SCOPE:NAME" | wc -l

result2=$?
echo $result2
if [ "$result2" != "0" ]; then
    echo "rucio did show failed"
else
    echo "rucio did show succeeded"
fi

exit 0
