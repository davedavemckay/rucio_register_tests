source /sdf/group/rubin/sw/htcondor.d/k8s_frdf/env.sh
source /sdf/group/rubin/sw/w_latest/loadLSST.bash
setup lsst_distrib -t w_latest

setup -j -r /sdf/data/rubin/user/dmckayuk/htcondor_runs/remote_submission/DM-53494/ctrl_bps
setup -j -r /sdf/data/rubin/user/dmckayuk/htcondor_runs/remote_submission/DM-53494/ctrl_bps_htcondor

eups list | grep LOCAL

set -o physical