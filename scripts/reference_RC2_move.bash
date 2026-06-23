#!/bin/bash
export BUTLER_REPO=hsc_pdr2_multisite
export SCOPE=hsc_pdr2_multisite


rucio whoami

#this makes a rucio_register config file for the hsc_pdr2_multisite repo at the remote site


cat <<EOF >rucio_register.cfg
rucio_rse: "RAL_BUTLER_DISK"
scope: "hsc_pdr2_multisite"
rse_root: "/lsst:datadisk/repos/hsc_pdr2_multisite/"
dtn_url: "https://webdav.echo.stfc.ac.uk:1094/lsst:datadisk/repos/hsc_pdr2_multisite/"
EOF

export COLLECTION=HSC/runs/RC2/w_2026_23/DM-55174
export DATASET=Dataset/HSC/runs/RC2/w_2026_23/DM-55174/RAL/outputs
export CONFIG_FILE=rucio_register.cfg
date
for TYPE in \
    'deepCoadd_calexp' \
    'deepCoadd_mergeDet' \
    'deepCoadd_calexp_background' \
    'goodSeeingCoadd' \
    'finalVisitSummary' \
    'matchedPreVisitCore_metrics' \
    'matchedVisitCore_metrics' \
    'objectTableColumnValidate_metrics' \
    'objectTableCore_metrics' \
    'objectTable_tract_gaia_dr3_20230707_match_astrom_metrics' \
    'sourceObjectTable_metrics' \
    'sourceTable_visit_gaia_dr3_20230707_match_astrom_metrics' \
    'ResourceUsageSummary' \
    'ccdVisitTable' \
    'visitTable' \
    'sourceTable_visit' \
    'objectTable_tract' \
    'forcedSourceTable_tract' \
    'diaObjectTable_tract' \
    'diaSourceTable_tract' \
    'ResourceUsageSummary' \
    '*Plot*'
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
date
result1=$?
echo $result1
if [ "$result1" != "0" ]; then
    echo "Butler Command 1 Failed"
else
    echo "Successful Butler Command 1"
fi

#this rule in rucio launches the move from RAL to SLAC

rucio rule add $SCOPE:$DATASET --copies 2 --rses RAL_BUTLER_DISK\|SLAC_BUTLER_DISK

sleep 20

rucio replica list dataset  $SCOPE:$DATASET

result2=$?
echo $result2

if [ "$result2" != "0" ]; then
    echo "Butler Command 2 Failed"
else
    echo "Successful Butler 2 Command"
fi

if  [ $result1  != "0"  -o  $result2  != "0" ]; then
        exit 1
fi

exit 0