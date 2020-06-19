#!/usr/bin/env bash

DBURL="https://s3.us-east-2.amazonaws.com/node-dbs.chainweb.com/db-chainweb-node-ubuntu.18.04-latest.tar.gz"
DBDIR="/data/chainweb-db"

# 

# Install database
mkdir -p "$DBDIR" && \
curl "$DBURL" | tar -xzC "$DBDIR"

