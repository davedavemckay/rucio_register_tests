#!/bin/bash
SITE=$1
COLLECTION=$2
PIPELINE_RUN_TICKET=$3
TEST=$4
BUTLER_REPO="dp2_prep"

if [ -z "$SITE" ] || [ -z "$COLLECTION" ] || [ -z "$PIPELINE_RUN_TICKET" ] || [ -z "$TEST" ]; then
    echo "Usage: $0 <SITE> <COLLECTION> <PIPELINE_RUN_TICKET> <TEST_NAME>"
    exit 1
fi

if [[ "$TEST" == *.yaml ]]; then
    TEST_NAME="${TEST%.yaml}"
elif [[ "$TEST" == *.bash ]]; then
    TEST_NAME="${TEST%.bash}"
else
    TEST_NAME="$TEST"
fi

if [ $SITE = "LANCS" ]; then
    RSE_ROOT="/cephfs/grid/lsst/repos/${BUTLER_REPO}/"
    DTN_URL="davs://xgate.hec.lancs.ac.uk:1094${RSE_ROOT}"
    if [ $TEST = "test_checksum_mechanisms" ]; then
        TEST_FILE="u/dmckayuk/w_2026_23/DM-55252/20260619T131002Z/analyzeSingleVisitStarAssociation_log/6119/analyzeSingleVisitStarAssociation_log_LSSTCam_6119_lsst_cells_v2_u_dmckayuk_w_2026_23_DM-55252_20260619T131002Z.json"
    fi
elif [ $SITE = "RAL" ]; then
    RSE_ROOT="/lsst:datadisk/butler/repos/${BUTLER_REPO}/"
    DTN_URL="davs://webdav.echo.stfc.ac.uk:1094${RSE_ROOT}"
    if [ $TEST = "test_checksum_mechanisms" ]; then
        TEST_FILE="u/dmckayuk/w_2026_23/DM-55251/20260618T080828Z/analyzeSingleVisitStarAssociation_log/6105/analyzeSingleVisitStarAssociation_log_LSSTCam_6105_lsst_cells_v2_u_dmckayuk_w_2026_23_DM-55251_20260618T080828Z.json"
    fi
else
    echo "Unknown SITE: $SITE"
    exit 1
fi

# bash file edits
set +x

sed -e "s|TEMPLATE_SITE|$SITE|g" ${TEST_NAME}_TEMPLATE.bash \
    -e "s|TEMPLATE_COLLECTION|$COLLECTION|g" \
    -e "s|TEMPLATE_TICKET|$PIPELINE_RUN_TICKET|g" \
    -e "s|TEMPLATE_TEST_NAME|$TEST_NAME|g" \
    -e "s|TEMPLATE_RSE_ROOT|$RSE_ROOT|g" \
    -e "s|TEMPLATE_DTN_URL|$DTN_URL|g" \
    > ${TEST_NAME}.bash.tmp && mv ${TEST_NAME}.bash.tmp ${TEST_NAME}_${SITE}.bash

if [ $TEST = "test_checksum_mechanisms" ]; then
    sed -i "s|TEMPLATE_TEST_FILE|$TEST_FILE|g" ${TEST_NAME}_${SITE}.bash
fi

# yaml file edits

sed -e "s|TEMPLATE_COMPUTE_SITE|$SITE|g" ${TEST_NAME}_TEMPLATE.yaml \
    -e "s|TEMPLATE_NODESET|${SITE}|g" \
    -e "s|TEMPLATE_COLLECTION|$COLLECTION|g" \
    -e "s|TEMPLATE_TICKET|$PIPELINE_RUN_TICKET|g" \
    -e "s|TEMPLATE_TEST_NAME|$TEST_NAME|g" \
    -e "s|TEMPLATE_BASH_FILE|${TEST_NAME}_${SITE}.bash|g" \
    > ${TEST_NAME}.yaml.tmp && mv ${TEST_NAME}.yaml.tmp ${TEST_NAME}_${SITE}.yaml

chmod a+x ${TEST_NAME}_${SITE}.bash

echo "Generated ${TEST_NAME}_${SITE}.bash and ${TEST_NAME}_${SITE}.yaml with the following parameters:"
echo "SITE: $SITE"
echo "COLLECTION: $COLLECTION"
echo "PIPELINE_RUN_TICKET: $PIPELINE_RUN_TICKET"
echo "TEST: $TEST_NAME"
echo "BUTLER_REPO: $BUTLER_REPO"
echo "RSE_ROOT: $RSE_ROOT"
echo "DTN_URL: $DTN_URL"
echo "TEST_FILE: $TEST_FILE"
set -x