#!/bin/bash
export BUTLER_REPO=dp2_prep
export SITE_RSE=RAL_BUTLER_DISK
export LSST_WEEKLY=w_2026_23

source ral_setup.bash $LSST_WEEKLY

rucio whoami

#this makes a rucio_register config file for the hsc_pdr2_multisite repo at the remote site
cat <<EOF >rucio_register.cfg
rucio_rse: "${SITE_RSE}"
scope: "${BUTLER_REPO}"
rse_root: "/lsst:datadisk/repos/${BUTLER_REPO}/"
dtn_url: "https://webdav.echo.stfc.ac.uk:1094/lsst:datadisk/repos/${BUTLER_REPO}/"
EOF

export COLLECTION=u/dmckayuk/w_2026_23/DM-55251/20260618T080828Z
export DATASET=Dataset/u/dmckayuk/w_2026_23/DM-55251/20260618T080828Z/outputs
export CONFIG_FILE=rucio_register.cfg
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