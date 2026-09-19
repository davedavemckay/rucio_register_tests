#!/bin/bash
export BUTLER_REPO="dp2_prep"
export SCOPE="dp2_prep"
export COLLECTION="TEMPLATE_COLLECTION"
export SITE="TEMPLATE_SITE"
export PIPELINE_RUN_TICKET="TEMPLATE_TICKET"
export TEST_NAME="DM-55271-test_8"
export TIMESTAMP=$((`date +%s` % 10000))
export TRANSFER_LIST_YAML="https://raw.githubusercontent.com/lsst-dm/datasettype_transfer_lists/refs/heads/main/cm_transfer_list.yaml"

rucio whoami

cat <<EOF >rucio_register.cfg
rucio_rse: "${SITE}_BUTLER_DISK"
scope: "${SCOPE}"
rse_root: TEMPLATE_RSE_ROOT
dtn_url: TEMPLATE_DTN_URL
EOF

export DATASET_PREFIX="Dataset/LSSTCam/runs/${BUTLER_REPO}/w_2026_23/${PIPELINE_RUN_TICKET}/${SITE}/${TEST_NAME}/${TIMESTAMP}"
export CONFIG_FILE="rucio_register.cfg"
echo "Time: $(date +%s.%N) - Starting rucio-register for $TEST_NAME $PIPELINE_RUN_TICKET at $SITE"

## WARNING the max-dataset-types is set to None by default in the code, and will register all dataset types.

rucio-register auto-register \
--root-chain "$COLLECTION" \
--repo "$BUTLER_REPO" \
--rucio-register-config "$CONFIG_FILE" \
--transfer-list "$TRANSFER_LIST_YAML" \
--dataset-name-prefix "$DATASET_PREFIX"

result1=$?
echo "Time: $(date +%s.%N) - Finished rucio-register auto-register for $TEST_NAME $PIPELINE_RUN_TICKET at $SITE "

echo $result1
if [ "$result1" != "0" ]; then
    echo "rucio-register $TEST_NAME Failed"
else
    echo "rucio-register $TEST_NAME Succeeded"
fi

# Discover all auto-generated datasets using rucio list-dids / rucio did list
echo "Time: $(date +%s.%N) - Discovering datasets matching prefix ${SCOPE}:${DATASET_PREFIX}*"
DATASET_LIST=$(rucio list-dids "${SCOPE}:${DATASET_PREFIX}*" --type dataset --short 2>/dev/null || rucio did list "${SCOPE}:${DATASET_PREFIX}*" --type dataset --short)

result2=0
if [ -z "$DATASET_LIST" ]; then
    echo "No datasets found matching prefix ${SCOPE}:${DATASET_PREFIX}*"
    result2=1
else
    echo "Found datasets to replicate:"
    echo "$DATASET_LIST"

    FORMATTED_DIDS=()
    for DATASET in $DATASET_LIST; do
        if [[ "$DATASET" == *:* ]]; then
            FORMATTED_DIDS+=("$DATASET")
        else
            FORMATTED_DIDS+=("${SCOPE}:${DATASET}")
        fi
    done

    COMMAS_DIDS=$(IFS=,; echo "${FORMATTED_DIDS[*]}")

    echo "Time: $(date +%s.%N) - Adding replication rule for all datasets to SLAC_BUTLER_DISK: $COMMAS_DIDS"
    rucio rule add $COMMAS_DIDS --copies 2 --rses ${SITE}_BUTLER_DISK\|SLAC_BUTLER_DISK
    result2=$?
    if [ "$result2" != "0" ]; then
        echo "rucio rule add failed for $COMMAS_DIDS"
    fi

    # Commented out for now as a sanity check:
    # sleep 20
    # for DID in "${FORMATTED_DIDS[@]}"; do
    #     echo "Time: $(date +%s.%N) - Listing dataset replicas for $DID"
    #     rucio replica list dataset $DID
    # done
fi

if [ "$result1" != "0" ] || [ "$result2" != "0" ]; then
    echo "rucio-register $TEST_NAME Failed"
    exit 1
fi

echo "rucio-register $TEST_NAME Succeeded"
echo "End Time: $(date +%s.%N)"

exit 0
