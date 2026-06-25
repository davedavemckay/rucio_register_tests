weekly=$1
source /cvmfs/sw.lsst.eu/almalinux-x86_64/lsst_distrib/$weekly/loadLSST.bash
setup lsst_distrib
export DAF_BUTLER_REPOSITORY_INDEX=/home/pool/lsstsgm/butler-repos-index.yaml
export LSST_DB_AUTH=~/butler_repos/db-auth.yaml
export X509_USER_PROXY=/tmp/x509up_u$(id -u)
export LSST_HTTP_CACERT_BUNDLE=/etc/grid-security/certificates/
export LSST_HTTP_AUTH_CLIENT_CERT=/tmp/x509up_u$(id -u)
export LSST_HTTP_AUTH_CLIENT_KEY=/tmp/x509up_u$(id -u)
export LSST_RESOURCES_WEBDAV_CONFIG=/home/pool/lsstsgm/.webdav.config