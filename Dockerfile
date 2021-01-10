# syntax=docker/dockerfile:experimental

# Run as
#
# --ulimit nofile=64000:64000

# BUILD PARAMTERS
ARG UBUNTUVER=20.04

FROM ubuntu:${UBUNTUVER}

ARG REVISION=15111ad
ARG GHCVER=8.8.4
ARG UBUNTUVER
ARG STRIP=1

LABEL revision="$REVISION"
LABEL ghc="$GHCVER"
LABEL ubuntu="$UBUNTUVER"

# install prerequisites
RUN apt-get update \
    && apt-get install -y librocksdb-dev curl xxd openssl binutils \
    && rm -rf /var/lib/apt/lists/*

# Install chainweb applications
WORKDIR /chainweb
RUN curl -Ls "https://kadena-cabal-cache.s3.amazonaws.com/chainweb-node/chainweb.${GHCVER}.ubuntu-${UBUNTUVER}.${REVISION}.tar.gz" \
    | tar -xzC "/" \
        chainweb/chainweb-node \
        chainweb/LICENSE \
        chainweb/README.md \
        chainweb/CHANGELOG.md \
    && { [ $STRIP -eq 1 ] && strip chainweb-node ; }

# Install scripts
COPY check-reachability.sh .
COPY run-chainweb-node.sh .
COPY initialize-db.sh .
COPY chainweb.mainnet01.yaml .
COPY chainweb.testnet04.yaml .
COPY chainweb.development.yaml .
COPY check-health.sh .
RUN chmod 755 check-reachability.sh run-chainweb-node.sh initialize-db.sh check-health.sh

# Create Database directories
RUN mkdir -p /data/chainweb-db \
    mkdir -p /root/.local/share/chainweb-node/mainnet01/ \
    mkdir -p /root/.local/share/chainweb-node/testnet04/ \
    mkdir -p /root/.local/share/chainweb-node/development/

# Command
STOPSIGNAL SIGTERM
EXPOSE 80
EXPOSE 1789
HEALTHCHECK --start-period=5m --interval=1m --retries=5 --timeout=10s CMD ./check-health.sh

CMD ./run-chainweb-node.sh

