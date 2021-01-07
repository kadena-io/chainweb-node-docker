#!/usr/bin/env bash

DBURL=${DBURL:-https://s3.us-east-2.amazonaws.com/node-dbs.chainweb.com/db-chainweb-node-ubuntu.18.04-latest.tar.gz}
DBDIR="/data/chainweb-db"

CHAINWEB_NETWORK=${CHAINWEB_NETWORK:-mainnet01}

# Install database

if [[ "$CHAINWEB_NETWORK" = "mainnet01" ]] ; then
    mkdir -p "$DBDIR/0" && \
    curl "$DBURL" | tar -xzC "$DBDIR/0"
fi

