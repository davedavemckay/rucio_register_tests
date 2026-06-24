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
    sys.exit("Usage: python find_dataset_counts.py <collection> [dataset_type]")

# Create the Butler
# Initialize the Butler
butler = Butler("dp2_prep", collections=collections)
if discover_dataset_types:
    # Discover the dataset types
    dataset_types = butler.query_dataset_types()
else:
    dataset_types = [dataset_type]

# Query the datasets and cast the generator to a list
for dataset_type in dataset_types:
    print(f"{sys.argv[1]},{len(list(butler.query_datasets(dataset_type, limit=None)))}")