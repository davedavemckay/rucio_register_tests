#!/bin/bash

job_id=$1

sed "s/TEMPLATE_JOB_ID/$job_id/g" condor_tail_TEMPLATE.sub > condor_tail_${job_id}.sub

tail_job_id=$(condor_submit -file condor_tail_${job_id}.sub | grep "submitted" | awk '{print $NF}' | sed 's/\.//g')
sleep 5
more condor_tail.${tail_job_id}.out
