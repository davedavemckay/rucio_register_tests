#!/bin/bash
SITE=$1
COLLECTION=$2
PIPELINE_RUN_TICKET=$3
TEST=$4
BUTLER_REPO="d2p_prep"

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
    DTN_URL="davs://xgate.hec.lancs.ac.uk:1094${RSE_ROOT}/"
elif [ $SITE = "RAL" ]; then
    RSE_ROOT="/lsst:datadisk/repos/${BUTLER_REPO}/"
    DTN_URL="https://webdav.echo.stfc.ac.uk:1094${RSE_ROOT}"
else
    echo "Unknown SITE: $SITE"
    exit 1
fi

# bash file edits

sed "s/TEMPLATE_SITE/$SITE/g" DM-55271_test_1_1type_TEMPLATE.bash > DM-55271_test_1_1type.bash.tmp && mv DM-55271_test_1_1type.bash.tmp DM-55271_test_1_1type.bash
sed "s/TEMPLATE_COLLECTION/$COLLECTION/g" DM-55271_test_1_1type.bash > DM-55271_test_1_1type.bash.tmp && mv DM-55271_test_1_1type.bash.tmp DM-55271_test_1_1type.bash
sed "s/TEMPLATE_TICKET/$PIPELINE_RUN_TICKET/g" DM-55271_test_1_1type.bash > DM-55271_test_1_1type.bash.tmp && mv DM-55271_test_1_1type.bash.tmp DM-55271_test_1_1type.bash
sed "s/TEMPLATE_RSE_ROOT/$RSE_ROOT/g" DM-55271_test_1_1type.bash > DM-55271_test_1_1type.bash.tmp && mv DM-55271_test_1_1type.bash.tmp DM-55271_test_1_1type.bash
sed "s/TEMPLATE_DTN_URL/$DTN_URL/g" DM-55271_test_1_1type.bash > DM-55271_test_1_1type.bash.tmp && mv DM-55271_test_1_1type.bash.tmp DM-55271_test_1_1type.bash

# yaml file edits

sed "s/TEMPLATE_COMPUTE_SITE/$SITE/g" DM-55271_test_1_TEMPLATE.yaml > DM-55271_test_1_TEMPLATE.yaml.tmp && mv DM-55271_test_1_TEMPLATE.yaml.tmp DM-55271_test_1_TEMPLATE.yaml
sed "s/TEMPLATE_COMPUTE_SITE_LOWERCASE/${SITE,,}/g" DM-55271_test_1_TEMPLATE.yaml > DM-55271_test_1_TEMPLATE.yaml.tmp && mv DM-55271_test_1_TEMPLATE.yaml.tmp DM-55271_test_1_TEMPLATE.yaml
sed "s/TEMPLATE_NODESET/${SITE}/g" DM-55271_test_1_TEMPLATE.yaml > DM-55271_test_1_TEMPLATE.yaml.tmp && mv DM-55271_test_1_TEMPLATE.yaml.tmp DM-55271_test_1_TEMPLATE.yaml
sed "s/TEMPLATE_COLLECTION/$COLLECTION/g" DM-55271_test_1_TEMPLATE.yaml > DM-55271_test_1_TEMPLATE.yaml.tmp && mv DM-55271_test_1_TEMPLATE.yaml.tmp DM-55271_test_1_TEMPLATE.yaml
sed "s/TEMPLATE_TICKET/$PIPELINE_RUN_TICKET/g" DM-55271_test_1_TEMPLATE.yaml > DM-55271_test_1_TEMPLATE.yaml.tmp && mv DM-55271_test_1_TEMPLATE.yaml.tmp DM-55271_test_1_TEMPLATE.yaml
sed "s/TEMPLATE_TEST_NAME/$TEST_NAME/g" DM-55271_test_1_TEMPLATE.yaml > DM-55271_test_1_TEMPLATE.yaml.tmp && mv DM-55271_test_1_TEMPLATE.yaml.tmp DM-55271_test_1_TEMPLATE.yaml
sed "s/TEMPLATE_BASH_FILE/DM-55271_test_1_1type.bash/g" DM-55271_test_1_TEMPLATE.yaml > DM-55271_test_1_TEMPLATE.yaml.tmp && mv DM-55271_test_1_TEMPLATE.yaml.tmp DM-55271_test_1_TEMPLATE.yaml

echo "Generated DM-55271_test_1_1type.bash and DM-55271_test_1_TEMPLATE.yaml with the following parameters:"
echo "SITE: $SITE"
echo "COLLECTION: $COLLECTION"
echo "PIPELINE_RUN_TICKET: $PIPELINE_RUN_TICKET"
echo "TEST: $TEST"
echo "BUTLER_REPO: $BUTLER_REPO"
echo "RSE_ROOT: $RSE_ROOT"
echo "DTN_URL: $DTN_URL"