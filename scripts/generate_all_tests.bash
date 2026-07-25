#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

SITE=""
COLLECTION=""
PIPELINE_RUN_TICKET=""

usage() {
    echo "Usage: $0 --site <SITE> --collection <COLLECTION> --pipeline-run-ticket <PIPELINE_RUN_TICKET>"
    echo "   or: $0 -s <SITE> -c <COLLECTION> -t <PIPELINE_RUN_TICKET>"
    echo "   or: $0 <SITE> <COLLECTION> <PIPELINE_RUN_TICKET>"
    echo ""
    echo "Options:"
    echo "  -s, --site                  Compute site (e.g., LANCS, RAL)"
    echo "  -c, --collection            Butler collection name"
    echo "  -t, --ticket, --pipeline-run-ticket"
    echo "                              Pipeline run ticket identifier"
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

if [ -z "$SITE" ] || [ -z "$COLLECTION" ] || [ -z "$PIPELINE_RUN_TICKET" ]; then
    echo "Error: SITE, COLLECTION, and PIPELINE_RUN_TICKET are required." >&2
    usage
fi

cd "$SCRIPT_DIR"

TEST_NAMES=()
for file in DM-55271*_TEMPLATE.bash DM-55271*_TEMPLATE.yaml; do
    [ -e "$file" ] || continue
    test_name="${file%_TEMPLATE.bash}"
    test_name="${test_name%_TEMPLATE.yaml}"
    TEST_NAMES+=("$test_name")
done

if [ ${#TEST_NAMES[@]} -eq 0 ]; then
    echo "No template files starting with DM-55271 found in $SCRIPT_DIR" >&2
    exit 1
fi

# Deduplicate and sort test names
UNIQUE_TEST_NAMES=($(printf "%s\n" "${TEST_NAMES[@]}" | sort -u))

echo "Found ${#UNIQUE_TEST_NAMES[@]} test(s) starting with DM-55271:"
for t in "${UNIQUE_TEST_NAMES[@]}"; do
    echo "  - $t"
done
echo ""

for TEST_NAME in "${UNIQUE_TEST_NAMES[@]}"; do
    echo "=========================================="
    echo "Running generate_test.bash for: $TEST_NAME"
    echo "=========================================="
    "$SCRIPT_DIR/generate_test.bash" -s "$SITE" -c "$COLLECTION" -t "$PIPELINE_RUN_TICKET" -n "$TEST_NAME"
    echo ""
done
