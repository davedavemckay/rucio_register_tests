#!/bin/bash

job_id=$1

sed "s/TEMPLATE_JOB_ID/$job_id/g" condor_tail_TEMPLATE.sub > condor_tail_${job_id}.sub

condor_submit -f condor_tail_${job_id}.sub