#!/bin/bash
export BUTLER_REPO="dp2_prep"
export SCOPE="dp2_prep"
export COLLECTION="u/dmckayuk/w_2026_23/DM-55252/20260619T131002Z"
export SITE="LANCS"
export PIPELINE_RUN_TICKET="DM-55252"
export TEST_NAME="DM-55271-test_1"

rucio whoami

cat <<EOF >rucio_register.cfg
rucio_rse: "${SITE}_BUTLER_DISK"
scope: "${SCOPE}"
rse_root: "/lsst:datadisk/repos/${BUTLER_REPO}/"
dtn_url: "https://webdav.echo.stfc.ac.uk:1094/lsst:datadisk/repos/${BUTLER_REPO}/"
EOF

export DATASET="Dataset/LSSTCam/runs/${BUTLER_REPO}/w_2026_23/${PIPELINE_RUN_TICKET}/${SITE}/${TEST_NAME}"
export CONFIG_FILE="rucio_register.cfg"
echo "Time: $(date +%s.%N) - Starting rucio-register for $TEST_NAME $PIPELINE_RUN_TICKET at $SITE"

# use first 10 dataset types from the butler query-dataset-types command for the given collection
butler query-dataset-types "$BUTLER_REPO" --collections "$COLLECTION" | tail -n +3 | head -n 10 | while IFS= read -r TYPE; do
    echo "type $TYPE"

    rucio-register data-products \
    --repo "$BUTLER_REPO" \
    --dataset-type "$TYPE" \
    --collections "$COLLECTION" \
    --rucio-dataset "$DATASET" \
    --rucio-register-config "$CONFIG_FILE" \
    --log-level DEBUG \
    --chunk-size 30
done

echo "Time: $(date +%s.%N) - Finished rucio-register for $TEST_NAME $PIPELINE_RUN_TICKET at $SITE "

result1=$?
echo $result1
if [ "$result1" != "0" ]; then
    echo "rucio-register $TEST_NAME Failed"
else
    echo "rucio-register $TEST_NAME Succeeded"
fi
exit 0
