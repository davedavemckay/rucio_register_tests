#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

SITE=""
COLLECTION=""
PIPELINE_RUN_TICKET=""
TEST=""
BUTLER_REPO="dp2_prep"

usage() {
    echo "Usage: $0 --site <SITE> --collection <COLLECTION> --pipeline-run-ticket <PIPELINE_RUN_TICKET> --test-name <TEST_NAME>"
    echo "   or: $0 -s <SITE> -c <COLLECTION> -t <PIPELINE_RUN_TICKET> -n <TEST_NAME>"
    echo "   or: $0 <SITE> <COLLECTION> <PIPELINE_RUN_TICKET> <TEST_NAME>"
    echo ""
    echo "Options:"
    echo "  -s, --site                  Compute site (e.g., LANCS, RAL)"
    echo "  -c, --collection            Butler collection name"
    echo "  -t, --ticket, --pipeline-run-ticket"
    echo "                              Pipeline run ticket identifier"
    echo "  -n, --name, --test, --test-name"
    echo "                              Test name or template filename"
    echo "  -h, --help                  Show this help message"
    exit 1
}

POSITIONAL_ARGS=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        -s|--site)
            SITE="$2"
            shift 2
            ;;
        --site=*)
            SITE="${1#*=}"
            shift
            ;;
        -c|--collection)
            COLLECTION="$2"
            shift 2
            ;;
        --collection=*)
            COLLECTION="${1#*=}"
            shift
            ;;
        -t|--ticket|--pipeline-run-ticket)
            PIPELINE_RUN_TICKET="$2"
            shift 2
            ;;
        --ticket=*|--pipeline-run-ticket=*)
            PIPELINE_RUN_TICKET="${1#*=}"
            shift
            ;;
        -n|--name|--test|--test-name)
            TEST="$2"
            shift 2
            ;;
        --name=*|--test=*|--test-name=*)
            TEST="${1#*=}"
            shift
            ;;
        -h|--help)
            usage
            ;;
        -*|--*)
            echo "Error: Unknown option $1" >&2
            usage
            ;;
        *)
            POSITIONAL_ARGS+=("$1")
            shift
            ;;
    esac
done

# Fallback to positional arguments if flags were not provided
if [ -z "$SITE" ] && [ ${#POSITIONAL_ARGS[@]} -gt 0 ]; then
    SITE="${POSITIONAL_ARGS[0]}"
fi
if [ -z "$COLLECTION" ] && [ ${#POSITIONAL_ARGS[@]} -gt 1 ]; then
    COLLECTION="${POSITIONAL_ARGS[1]}"
fi
if [ -z "$PIPELINE_RUN_TICKET" ] && [ ${#POSITIONAL_ARGS[@]} -gt 2 ]; then
    PIPELINE_RUN_TICKET="${POSITIONAL_ARGS[2]}"
fi
if [ -z "$TEST" ] && [ ${#POSITIONAL_ARGS[@]} -gt 3 ]; then
    TEST="${POSITIONAL_ARGS[3]}"
fi

if [ -z "$SITE" ] || [ -z "$COLLECTION" ] || [ -z "$PIPELINE_RUN_TICKET" ] || [ -z "$TEST" ]; then
    echo "Error: SITE, COLLECTION, PIPELINE_RUN_TICKET, and TEST_NAME are required." >&2
    usage
fi

cd "$SCRIPT_DIR"

if [[ "$TEST" == *.yaml ]]; then
    TEST_NAME="${TEST%.yaml}"
elif [[ "$TEST" == *.bash ]]; then
    TEST_NAME="${TEST%.bash}"
else
    TEST_NAME="$TEST"
fi

if [ "$SITE" = "LANCS" ]; then
    RSE_ROOT="/cephfs/grid/lsst/repos/${BUTLER_REPO}/"
    DTN_URL="https://xgate.hec.lancs.ac.uk:1094${RSE_ROOT}"
    if [ "$TEST_NAME" = "test_checksum_mechanisms" ] || [ "$TEST" = "test_checksum_mechanisms" ]; then
        TEST_FILE="u/dmckayuk/w_2026_23/DM-55252/20260619T131002Z/analyzeSingleVisitStarAssociation_log/6119/analyzeSingleVisitStarAssociation_log_LSSTCam_6119_lsst_cells_v2_u_dmckayuk_w_2026_23_DM-55252_20260619T131002Z.json"
    fi
elif [ "$SITE" = "RAL" ]; then
    RSE_ROOT="/lsst:datadisk/butler/repos/${BUTLER_REPO}/"
    DTN_URL="https://webdav.echo.stfc.ac.uk:1094${RSE_ROOT}"
    if [ "$TEST_NAME" = "test_checksum_mechanisms" ] || [ "$TEST" = "test_checksum_mechanisms" ]; then
        TEST_FILE="u/dmckayuk/w_2026_23/DM-55251/20260618T080828Z/analyzeSingleVisitStarAssociation_log/6105/analyzeSingleVisitStarAssociation_log_LSSTCam_6105_lsst_cells_v2_u_dmckayuk_w_2026_23_DM-55251_20260618T080828Z.json"
    fi
else
    echo "Unknown SITE: $SITE" >&2
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

if [ "$TEST_NAME" = "test_checksum_mechanisms" ] || [ "$TEST" = "test_checksum_mechanisms" ]; then
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