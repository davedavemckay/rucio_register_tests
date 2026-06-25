if [ $# -eq 1 ]; then
    COLLECTION=$1
else
    echo "Usage: $0 <collection>"
    echo "Example collections: u/dmckayuk/w_2026_23/DM-55251/20260618T080828Z"
    echo "Example collections: u/dmckayuk/w_2026_23/DM-55252/20260619T131002Z"
    exit 1
fi
butler query-dataset-types dp2_prep --collections $COLLECTION