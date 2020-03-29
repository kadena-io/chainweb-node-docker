#!/usr/bin/env bash

# ############################################################################ #
# PARAMETERS

export CHAINWEB_NETWORK=${CHAINWEB_NETWORK:-mainnet01}
export CHAINWEB_BOOTSTRAP_NODE=${CHAINWEB_BOOTSTRAP_NODE:-us-w1.chainweb.com}
export CHAINWEB_PORT=${CHAINWEB_PORT:-443}
export LOGLEVEL=${LOGLEVEL:-warn}

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
# Run node

./chainweb-node \
    --config-file=chainweb.yaml \
    --hostname="$CHAINWEB_HOST" \
    --port="$CHAINWEB_PORT" \
    --log-level="$LOGLEVEL" \
    +RTS -N -t -A64M -H500M

