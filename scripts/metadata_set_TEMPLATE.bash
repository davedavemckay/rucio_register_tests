#!/bin/bash
export BUTLER_REPO="dp2_prep"
export SCOPE="dp2_prep"
export COLLECTION="TEMPLATE_COLLECTION"
export SITE="TEMPLATE_SITE"
export PIPELINE_RUN_TICKET="TEMPLATE_TICKET"
export TEST_NAME="metadata_set"
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

echo "Time: $(date +%s.%N) - Setting is_new=True for datasets matching ${SCOPE}:${DATASET_PREFIX}*"

python3 -c '
import os
import sys
from rucio.client.didclient import DIDClient

scope = os.environ.get("SCOPE", "dp2_prep")
prefix = os.environ.get("DATASET_PREFIX", "")

client = DIDClient()
dids = list(client.list_dids(scope=scope, filters={"name": f"{prefix}*"}, did_type="dataset"))
print(f"Found {len(dids)} datasets. Setting is_new=True...")

failed_count = 0
for name in dids:
    try:
        client.set_metadata(scope=scope, name=name, key="is_new", value=True)
    except Exception as e:
        print(f"Failed to set is_new for {scope}:{name}: {e}")
        failed_count += 1

if failed_count > 0:
    print(f"Failed to set is_new metadata for {failed_count} dataset(s)")
    sys.exit(1)

print("Successfully set is_new=True for all datasets.")
'

result1=$?
if [ "$result1" != "0" ]; then
    echo "metadata_set $TEST_NAME Failed"
    exit 1
else
    echo "metadata_set $TEST_NAME Succeeded"
fi

echo "End Time: $(date +%s.%N)"
exit 0
