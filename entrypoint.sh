#!/bin/bash

DEFAULT_SOCAT_PORT=5000
DEFAULT_STUNNEL_PORT=5001

if [ -z "${PEM_FILE}" ]
then
    echo "Environment variable PEM_FILE cannot be empty!"
    exit 1
fi

if [ -z "${ALMA_ENDPOINT}" ]
then
    echo "Environment variable ALMA_ENDPOINT cannot be empty!"
    exit 1
fi

while [ ! -f ${PEM_FILE} ]; do
    echo "Waiting for file: ${PEM_FILE}"
    sleep 5
done

if [ -z "${SOCAT_PORT}" ]
then
    SOCAT_PORT=DEFAULT_SOCAT_PORT
fi

if [ -z "${STUNNEL_PORT}" ]
then
    STUNNEL_PORT=DEFAULT_STUNNEL_PORT
fi

echo "Starting container..."
CONF_FILE="stunnel.conf"

echo "Preparing stunnel config..."
exec 3>&1 1>>${CONF_FILE}
    echo "debug = 3"
    echo "fips = no"
    echo "options = NO_SSLv2"
    echo
    echo "[Alma]"
    echo "key = ${PEM_FILE}"
    echo "cert = ${PEM_FILE}"
    echo "client = yes"
    echo "accept = ${STUNNEL_PORT}"
    echo "connect = ${ALMA_ENDPOINT}"
    echo "TIMEOUTclose = 0"
    echo "TIMEOUTconnect = 200"
    echo "TIMEOUTidle = 86400"
    echo
exec 1>&3 3>&-
echo

if [ -f ${CONF_FILE} ]
then
    echo "Starting stunnel..."
    stunnel ${CONF_FILE}
    echo
fi

echo "Starting socat..."
while true; do
  socat -v tcp-listen:${SOCAT_PORT},reuseaddr,fork,keepalive tcp:localhost:${STUNNEL_PORT}
done
