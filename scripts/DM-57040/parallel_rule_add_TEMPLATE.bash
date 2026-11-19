#!/bin/bash
export BUTLER_REPO="dp2_prep"
export SCOPE="dp2_prep"
export COLLECTION="TEMPLATE_COLLECTION"
export SITE="TEMPLATE_SITE"
export PIPELINE_RUN_TICKET="TEMPLATE_TICKET"
export TEST_NAME="parallel_rule_add"
export TIMESTAMP=$((`date +%s` % 10000))
export TRANSFER_LIST_YAML="https://raw.githubusercontent.com/lsst-dm/datasettype_transfer_lists/refs/heads/main/cm_transfer_list.yaml"
export DATASET_PREFIX="Dataset/LSSTCam/runs/${BUTLER_REPO}/w_2026_35/${PIPELINE_RUN_TICKET}"
export CONFIG_FILE="rucio_register.cfg"

rucio whoami

cat <<EOF >rucio_register.cfg
rucio_rse: "${SITE}_BUTLER_DISK"
scope: "${SCOPE}"
rse_root: TEMPLATE_RSE_ROOT
dtn_url: TEMPLATE_DTN_URL
EOF

# Discover all auto-generated datasets using rucio did list
echo "Time: $(date +%s.%N) - Discovering datasets matching prefix ${SCOPE}:${DATASET_PREFIX}*"
DATASET_LIST=$(rucio did list --short --filter type=DATASET "${SCOPE}:${DATASET_PREFIX}*" 2>/dev/null)
rucio_exit=$?
result2=0
if [ $rucio_exit -ne 0 ] || [ -z "$DATASET_LIST" ]; then
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

    echo "Time: $(date +%s.%N) - Adding replication rules to SLAC_BUTLER_DISK for ${#FORMATTED_DIDS[@]} datasets in parallel (10 workers)..."
    printf '%s\0' "${FORMATTED_DIDS[@]}" | xargs -0 -P 10 -n 1 rucio rule add --copies 2 --rses "${SITE}_BUTLER_DISK|SLAC_BUTLER_DISK"
    result2=$?

    if [ "$result2" != "0" ]; then
        echo "One or more rucio rule add processes failed."
    fi
fi

if [ "$result2" != "0" ]; then
    echo "rucio rule add Failed"
    echo "rucio rule add exit code: $result2"
    exit 1
fi

echo "rucio rule add Succeeded"
echo "End Time: $(date +%s.%N)"

exit 0
