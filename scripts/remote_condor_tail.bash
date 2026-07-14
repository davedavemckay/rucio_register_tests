#!/bin/bash
if [ $* -eq 1 ];
then
        job_id=$1
        max_bytes=1048576
elif [ $* -eq 2 ];
then
        job_id=$1
        max_bytes=$2
else
        echo "Usage: $0 <job-id> [<max-bytes>]"
        exit 1
fi
job_id=$(echo $job_id | awk -F. '{print $0}')
TEMP=$RANDOM
sed "s/TEMPLATE_JOB_ID/$job_id/g" condor_tail_TEMPLATE.sub > $TEMP
sed "s/TEMPLATE_MAX_BYTES/$max_bytes/g" $TEMP > condor_tail.${job_id}.sub
rm $TEMP
tail_job_id=$(condor_submit -file condor_tail.${job_id}.sub | grep "submitted" | awk '{print $NF}' | sed 's/\.//g')
echo condor_tail.${tail_job_id}.out
