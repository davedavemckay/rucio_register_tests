#!/bin/bash

if [ "$#" -ne 4 ]; then
    echo "Usage: $0 <SITE> <BUTLER_REPO> <LSST_WEEKLY> <TEST_NAME>"
    exit 1
fi

export BUTLER_REPO=$2
export LSST_WEEKLY=$3
export SITE=$1
export SITE_RSE=${SITE}_BUTLER_DISK
export SCOPE=${BUTLER_REPO}

if [ "$SITE" == "LANCS" ]; then
    export SITE_RSE_ROOT=/cephfs/grid/lsst/repos/${BUTLER_REPO}/
    export SITE_DTN_URL=davs://xgate.hec.lancs.ac.uk:1094/cephfs/grid/lsst/repos/${BUTLER_REPO}/
elif [ "$SITE" == "RAL" ]; then
    export SITE_RSE_ROOT=/lsst:datadisk/repos/${BUTLER_REPO}/
    export SITE_DTN_URL=https://webdav.echo.stfc.ac.uk:1094/lsst:datadisk/repos/${BUTLER_REPO}/
else
    echo "Unknown site: $SITE"
    exit 1
fi

source ${SITE}_setup.bash $LSST_WEEKLY

rucio whoami

#this makes a rucio_register config file for the hsc_pdr2_multisite repo at the remote site
cat <<EOF >rucio_register.cfg
rucio_rse: "${SITE_RSE}"
scope: "${SCOPE}"
rse_root: "${SITE_RSE_ROOT}"
dtn_url: "${SITE_DTN_URL}"
EOF

export COLLECTION=u/dmckayuk/w_2026_23/DM-55251/20260618T080828Z
export DATASET=Dataset/u/dmckayuk/w_2026_23/DM-55251/20260618T080828Z/${test_name}
export CONFIG_FILE=rucio_register.cfg
test_name=$4

echo "BEGIN REGISTRY: $(date)"
for TYPE in \
    analyzeSingleVisitStarAssociation_config \
    calibrateImage_config \
    consolidateSingleVisitStar_config \
    isrStatistics \
    isr_config \
    isr_log \
    isr_metadata \
    makeAnalysisSingleVisitStarAssociationMetricTable_config \
    makeAnalysisSingleVisitStarAssociationWholeSkyPlot_config \
    makeInitialVisitTable_config \
    post_isr_image \
    single_visit_star_schema \
    standardizeSingleVisitStar_config
do
        echo type $TYPE

        rucio-register data-products \
        --repo $BUTLER_REPO \
        --dataset-type $TYPE \
        --collections $COLLECTION \
        --rucio-dataset $DATASET \
        --rucio-register-config $CONFIG_FILE \
        --log-level DEBUG \
        --chunk-size 30
done
echo "END REGISTRY: $(date)"
result1=$?
echo $result1
if [ "$result1" != "0" ]; then
    echo "Butler Command 1 Failed"
else
    echo "Successful Butler Command 1"
fi

exit 0

#this rule in rucio launches the move from RAL to SLAC

# rucio rule add $SCOPE:$DATASET --copies 2 --rses RAL_BUTLER_DISK\|SLAC_BUTLER_DISK

# sleep 20

# rucio replica list dataset  $SCOPE:$DATASET

# result2=$?
# echo $result2

# if [ "$result2" != "0" ]; then
#     echo "Butler Command 2 Failed"
# else
#     echo "Successful Butler 2 Command"
# fi

# if  [ $result1  != "0"  -o  $result2  != "0" ]; then
#         exit 1
# fi

# exit 0