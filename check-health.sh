#!/usr/bin/env bash

export CHAINWEB_NETWORK=${CHAINWEB_NETWORK:-mainnet01}
export CHAINWEB_PORT=${CHAINWEB_PORT:-443}

curl -fsLk "https://localhost:$CHAINWEB_PORT/chainweb/0.0/$CHAINWEB_NETWORK/cut" || exit 1

