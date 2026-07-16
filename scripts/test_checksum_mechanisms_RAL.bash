#!/bin/bash
export BUTLER_REPO="dp2_prep"
export SCOPE="dp2_prep"
export COLLECTION="u/dmckayuk/w_2026_23/DM-55251"
export SITE="RAL"
export PIPELINE_RUN_TICKET="DM-55251"
export TEST_NAME="DM-55271-test_3a"
export TIMESTAMP=$((`date +%s` % 10000))
export RSE_ROOT="/lsst:datadisk/butler/repos/dp2_prep/"
export DTN_URL="davs://webdav.echo.stfc.ac.uk:1094/lsst:datadisk/butler/repos/dp2_prep/"
export TEST_FILE="u/dmckayuk/w_2026_23/DM-55251/20260618T080828Z/analyzeSingleVisitStarAssociation_log/6105/analyzeSingleVisitStarAssociation_log_LSSTCam_6105_lsst_cells_v2_u_dmckayuk_w_2026_23_DM-55251_20260618T080828Z.json"

export FULL_URI="${DTN_URL}${TEST_FILE}"

echo "Time: $(date +%s.%N) - Starting test for $TEST_NAME"

python3 "./rucio_register_tests/scripts/test_checksum_mechanisms.py" "$FULL_URI"

result1=$?
echo "Time: $(date +%s.%N) - Finished test for $TEST_NAME"

echo $result1
if [ "$result1" != "0" ]; then
    echo "$TEST_NAME Failed"
else
    echo "$TEST_NAME Succeeded"
fi

echo "End Time: $(date +%s.%N)"

exit 0
