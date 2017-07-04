#!/usr/bin/env bash
# https://github.com/uyamazak/gae_ssl_autoupdater/
DNS_PROJECT="YOUR-PROJECT"
GAE_PROJECT="YOUR-OTHER-PROJECT"
CERT_ID=`gcloud beta app --project $GAE_PROJECT ssl-certificates list | awk 'NR==2 {print $1}'`
CERT_NAME="letsencrypt-auto`date "+%Y%m%d"`"
TARGET_DOMAIN="example.com"
ZONE_NAME="zone-name-in-cloud-dns"
ACME_TTL=60
SLEEP_SECOND=60

function deploy_challenge {
    local DOMAIN="${1}" TOKEN_FILENAME="${2}" TOKEN_VALUE="${3}"

    if [ $DOMAIN = $TARGET_DOMAIN ];then
      echo "Set TXT record of _acme-challenge.$DOMAIN to $TOKEN_VALUE"
       echo "dns update start"
      gcloud dns --project=$DNS_PROJECT record-sets transaction start -z=${ZONE_NAME}
      gcloud dns --project=$DNS_PROJECT record-sets transaction remove \
        `gcloud --project=$DNS_PROJECT dns record-sets list -z=${ZONE_NAME} --name="_acme-challenge.${DOMAIN}." | awk 'NR==2 {print $4}'` \
         -z=${ZONE_NAME} --name="_acme-challenge.${DOMAIN}." --type=TXT --ttl=${ACME_TTL}
      gcloud dns --project=$DNS_PROJECT record-sets transaction add $TOKEN_VALUE -z=${ZONE_NAME} --name="_acme-challenge.${DOMAIN}." --type=TXT --ttl=${ACME_TTL}
      gcloud dns --project=$DNS_PROJECT record-sets transaction execute -z=${ZONE_NAME}
      echo "dns update end sleep ${SLEEP_SECOND}"
      sleep $SLEEP_SECOND
    else
      echo "Don't match $TARGET_DOMAIN and $DOMAIN"
      echo "Set TXT record of _acme-challenge.$DOMAIN to $TOKEN_VALUE manually"
      read
    fi
}

function clean_challenge {
    local DOMAIN="${1}" TOKEN_FILENAME="${2}" TOKEN_VALUE="${3}"
}

function deploy_cert {
    local DOMAIN="${1}" KEYFILE="${2}" CERTFILE="${3}" FULLCHAINFILE="${4}" CHAINFILE="${5}" TIMESTAMP="${6}"
    if [ $DOMAIN = $TARGET_DOMAIN ];then
      echo "update ssl cert start"
      gcloud beta app --project ${GAE_PROJECT} ssl-certificates update $CERT_ID \
        --display-name=$CERT_NAME \
        --certificate=$FULLCHAINFILE \
        --private-key=$KEYFILE
    else
      echo "Don't match $TARGET_DOMAIN and $DOMAIN"
    fi
}

function unchanged_cert {
    local DOMAIN="${1}" KEYFILE="${2}" CERTFILE="${3}" FULLCHAINFILE="${4}" CHAINFILE="${5}"
}

HANDLER=$1; shift; $HANDLER $@
