#!/usr/bin/env bash

# ############################################################################ #
# PARAMETERS

export CHAINWEB_NETWORK=${CHAINWEB_NETWORK:-mainnet01}
export CHAINWEB_BOOTSTRAP_NODE=${CHAINWEB_BOOTSTRAP_NODE:-us-e1.chainweb.com}
export CHAINWEB_PORT=${CHAINWEB_PORT:-443}
export LOGLEVEL=${LOGLEVEL:-warn}
export MINER_KEY=${MINER_KEY:-}
export MINER_ACCOUNT=${MINER_ACCOUNT:-$MINER_KEY}
export ENABLE_ROSETTA=${ENABLE_ROSETTA:-}

if [[ -z "$CHAINWEB_HOST" ]] ; then
    CHAINWEB_HOST=$(curl -sL 'https://api.ipify.org?format=text')
fi
export CHAINWEB_HOST

# ############################################################################ #
# Check ulimit

UL=$(ulimit -n -S)
[[ "$UL" -ge 65536 ]] ||
{
    echo "The configuration of the container has a too tight limit for the number of open file descriptors. The limit is $UL but at least 65536 is required." 1>&2
    echo "Try starting the container with '--ulimit \"nofile=65536:65536\"'" 1>&2
    exit 1
}

# ############################################################################ #
# Check connectivity

curl -fsL "https://$CHAINWEB_BOOTSTRAP_NODE/info" > /dev/null ||
{
    echo "Node is unable to connect the chainweb boostrap node: $CHAINWEB_BOOTSTRAP_NODE" 1>&2
    exit 1
}

./check-reachability.sh "$CHAINWEB_HOST" "$CHAINWEB_PORT" ||
{
    echo "Node is not reachable under its public host address $CHAINWEB_HOST:$CHAINWEB_PORT" 1>&2
    exit 1
}

# ############################################################################ #
# Create chainweb database directory
#
# The database location is configured in chainweb.yaml

DBDIR="/data/chainweb-db"
mkdir -p "$DBDIR/0"

# ############################################################################ #
# Configure Miner

if [[ -z "$MINER_KEY" ]] ; then
export MINER_CONFIG="
chainweb:
  mining:
    coordination:
      enabled: ${MINING_ENABLED:-false}
"
else
export MINER_CONFIG="
chainweb:
  mining:
    coordination:
      enabled: true
      miners:
        - account: $MINER_ACCOUNT
          public-keys: [ $MINER_KEY ]
          predicate: keys-all
"
fi

# ############################################################################ #
# Flags

if [[ -n "$ROSETTA" ]] ; then
    ROSETTA_FLAG="--rosetta"
else
    ROSETTA_FLAG="--no-rosetta"
fi

# ############################################################################ #
# Run node

exec ./chainweb-node \
    --config-file="chainweb.${CHAINWEB_NETWORK}.yaml" \
    --config-file <(echo "$MINER_CONFIG") \
    --hostname="$CHAINWEB_HOST" \
    --port="$CHAINWEB_PORT" \
    "$ROSETTA_FLAG" \
    --log-level="$LOGLEVEL" \
    +RTS -N -t -A64M -H500M -RTS \
    "$@"

