#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

SITE=""
COLLECTION=""
PIPELINE_RUN_TICKET=""
TICKET_BRANCH="DM-57040"

usage() {
    echo "Usage: $0 --site <SITE> --collection <COLLECTION> --pipeline-run-ticket <PIPELINE_RUN_TICKET> [--ticket-branch <TICKET_BRANCH>]"
    echo "   or: $0 -s <SITE> -c <COLLECTION> -t <PIPELINE_RUN_TICKET> [-b <TICKET_BRANCH>]"
    echo "   or: $0 <SITE> <COLLECTION> <PIPELINE_RUN_TICKET> [<TICKET_BRANCH>]"
    echo ""
    echo "Options:"
    echo "  -s, --site                  Compute site (e.g., LANCS, RAL)"
    echo "  -c, --collection            Butler collection name"
    echo "  -t, --ticket, --pipeline-run-ticket"
    echo "                              Pipeline run ticket identifier"
    echo "  -b, --branch, --ticket-branch"
    echo "                              Ticket branch / subfolder name (default: DM-57040, e.g., DM-55271)"
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
        -b|--branch|--ticket-branch)
            TICKET_BRANCH="$2"
            shift 2
            ;;
        --branch=*|--ticket-branch=*)
            TICKET_BRANCH="${1#*=}"
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
if [ ${#POSITIONAL_ARGS[@]} -gt 3 ]; then
    TICKET_BRANCH="${POSITIONAL_ARGS[3]}"
fi

if [ -z "$SITE" ] || [ -z "$COLLECTION" ] || [ -z "$PIPELINE_RUN_TICKET" ]; then
    echo "Error: SITE, COLLECTION, and PIPELINE_RUN_TICKET are required." >&2
    usage
fi

# Strip tickets/ prefix if provided (e.g., tickets/DM-57040 -> DM-57040)
TICKET_BRANCH="${TICKET_BRANCH#tickets/}"
TICKET_BRANCH="${TICKET_BRANCH%/}"

TARGET_DIR="$SCRIPT_DIR/$TICKET_BRANCH"
if [ ! -d "$TARGET_DIR" ]; then
    echo "Error: Ticket branch subfolder '$TARGET_DIR' does not exist." >&2
    exit 1
fi

cd "$TARGET_DIR"

TEST_NAMES=()
for file in *_TEMPLATE.bash *_TEMPLATE.yaml; do
    [ -e "$file" ] || continue
    test_name="${file%_TEMPLATE.bash}"
    test_name="${test_name%_TEMPLATE.yaml}"
    TEST_NAMES+=("$test_name")
done

if [ ${#TEST_NAMES[@]} -eq 0 ]; then
    echo "No template files found in $TARGET_DIR" >&2
    exit 1
fi

# Deduplicate and sort test names
UNIQUE_TEST_NAMES=($(printf "%s\n" "${TEST_NAMES[@]}" | sort -u))

echo "Found ${#UNIQUE_TEST_NAMES[@]} test(s) in $TICKET_BRANCH:"
for t in "${UNIQUE_TEST_NAMES[@]}"; do
    echo "  - $t"
done
echo ""

for TEST_NAME in "${UNIQUE_TEST_NAMES[@]}"; do
    echo "=========================================="
    echo "Running generate_test.bash for: $TICKET_BRANCH/$TEST_NAME"
    echo "=========================================="
    "$SCRIPT_DIR/generate_test.bash" -s "$SITE" -c "$COLLECTION" -t "$PIPELINE_RUN_TICKET" -b "$TICKET_BRANCH" -n "$TEST_NAME"
    echo ""
done
