weekly=$1
source /cvmfs/sw.lsst.eu/almalinux-x86_64/lsst_distrib/$weekly/loadLSST.bash
export X509_USER_PROXY=/tmp/x509up_u$(id -u)
export X509_CERT_DIR=/etc/grid-security/certificates
export LSST_HTTP_CACERT_BUNDLE=/cephfs/pool/gridapps/etc/grid-security/certificates
export LSST_HTTP_AUTH_CLIENT_CERT=${X509_USER_PROXY}
export LSST_HTTP_AUTH_CLIENT_KEY=${X509_USER_PROXY}
export LSST_DB_AUTH=~/.lsst/db-auth.yaml
export DAF_BUTLER_REPOSITORY_INDEX="davs://xgate.hec.lancs.ac.uk:1094/cephfs/grid/lsst/butler-repos-index.yaml"
export REPO=davs://xgate.hec.lancs.ac.uk:1094/cephfs/grid/lsst/repos/dp2_prep
export LSST_RESOURCES_WEBDAV_CONFIG=~/davs.yaml
export DATA=davs://xgate.hec.lancs.ac.uk:1094/cephfs/grid/lsst