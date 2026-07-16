#!/bin/bash
export BUTLER_REPO="dp2_prep"
export SCOPE="dp2_prep"
export COLLECTION="TEMPLATE_COLLECTION"
export SITE="TEMPLATE_SITE"
export PIPELINE_RUN_TICKET="TEMPLATE_TICKET"
export TEST_NAME="DM-55271-test_3a"
export TIMESTAMP=$((`date +%s` % 10000))
export RSE_ROOT="TEMPLATE_RSE_ROOT"
export DTN_URL="TEMPLATE_DTN_URL"
export TEST_FILE="TEMPLATE_TEST_FILE"

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
