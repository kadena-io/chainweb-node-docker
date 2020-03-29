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
# TODO check ulimit

# ############################################################################ #
# Run node

./chainweb-node \
    --config-file=chainweb.yaml \
    --hostname="$CHAINWEB_HOST" \
    --port="$CHAINWEB_PORT" \
    --log-level="$LOGLEVEL" \
    +RTS -N -t -A64M -H500M

