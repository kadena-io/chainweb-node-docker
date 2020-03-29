#!/usr/bin/env bash

# set -e

# ############################################################################ #
# PARAMETERS

HOST=$1
PORT=$2

CHAINWEB_NETWORK=${CHAINWEB_NETWORK:-testnet04}
CHAINWEB_BOOTSTRAP_NODE=${CHAINWEB_BOOTSTRAP_NODE:-us1.testnet.chainweb.com}

# ############################################################################ #
# Temporary files

CERTFILE=$(mktemp)
KEYFILE=$(mktemp)

trap '{ kill $(jobs -pr); wait $(jobs -pr) 2>/dev/null ; rm -f -- "$CERTFILE" "$KEYFILE" ; }' EXIT

# ############################################################################ #
# Utils

function create-certificate {
    openssl req \
        -x509 \
        -newkey rsa:4096 \
        -keyout "$KEYFILE" \
        -out "$CERTFILE" \
        -days 1 \
        -nodes \
        -subj "/CN=$HOST" \
        > /dev/null 2>&1
    get-fingerprint < "$CERTFILE"
}

function get-fingerprint {
    openssl x509 -fingerprint -noout -sha256 |
    sed 's/://g' |
    tail -c 65 |
    xxd -r -p |
    base64 |
    tr -d '=' |
    tr '/+' '_-'
}

function run-server {
    openssl s_server -port "$PORT" -cert "$CERTFILE" -key "$KEYFILE" -www -quiet &
}

# ############################################################################ #
# Perform Check

# Create certificate
CERTID=$(create-certificate)

# start server in the background
run-server

# make request to chainweb bootstrap node
PEER_INFO="{\"address\": {\"hostname\": \"$HOST\", \"port\": $PORT}, \"id\": \"$CERTID\"}"

curl "https://$CHAINWEB_BOOTSTRAP_NODE/chainweb/0.0/$CHAINWEB_NETWORK/cut/peer" \
    -sLk \
    -XPUT \
    -H 'content-type: application/json' \
    -H 'X-Chainweb-Node-Version: 1.7' \
    -v \
    -d "$PEER_INFO" 2>&1 |
    grep -q "< HTTP/2 204\|missing X-Chainweb-Node-Version header"

