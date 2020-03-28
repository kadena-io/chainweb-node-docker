#!/usr/bin/env bash

DBURL="https://s3.us-east-2.amazonaws.com/node-dbs.chainweb.com/db-chainweb-node-ubuntu.18.04-latest.tar.gz"
DBDIR="$HOME/.local/share/chainweb-node/mainnet01/0/"

# Install database
mkdir -p "$HOME/.local/share/chainweb-node/mainnet01/0/" && \
curl "$DBURL" | tar -xzC "$DBDIR"

