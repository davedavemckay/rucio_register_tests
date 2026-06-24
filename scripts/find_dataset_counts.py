import sys

from lsst.daf.butler import Butler

discover_dataset_types = False

if len(sys.argv) == 2:
    collections = sys.argv[1]
    discover_dataset_types = True
elif len(sys.argv) == 3:
    collections = sys.argv[1]
    dataset_type = sys.argv[2]
else:
    sys.exit("Usage: python find_dataset_counts.py <collection> [dataset_type]\nExample collections:\nu/dmckayuk/w_2026_23/DM-55251/20260618T080828Z\nu/dmckayuk/w_2026_23/DM-55252/20260619T131002Z")

# Create the Butler
# Initialize the Butler
butler = Butler("dp2_prep")

if discover_dataset_types:
    # Discover the dataset types
    info_list = butler.collections.query_info(collections, include_summary=True)

    if info_list:
        dataset_types = info_list[0].dataset_types
    else:
        sys.exit(f"No dataset types found for collection: {collections}")
else:
    dataset_types = [dataset_type]

# Query the datasets and cast the generator to a list
for dataset_type in dataset_types:
    print(f"{sys.argv[1]},{len(list(butler.query_datasets(dataset_type, limit=None)))}")