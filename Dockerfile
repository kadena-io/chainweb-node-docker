# syntax=docker/dockerfile:experimental

# Run as
#
# --ulimit nofile=64000:64000

FROM ubuntu:18.04

# install prerequisites
RUN apt-get update && apt-get install -y librocksdb-dev curl xxd openssl

# Install chainweb applications
WORKDIR /chainweb
# RUN curl -Ls "https://github.com/kadena-io/chainweb-node/releases/download/<chaineweb-version>/<chainweb-binary-version>" | tar -xzC "/chainweb/"
RUN curl -Ls "https://kadena-cabal-cache.s3.amazonaws.com/chainweb-node/chainweb.8.6.5.ubuntu-18.04.a08ac1b.tar.gz" | tar -xzC "/chainweb/"

COPY check-reachability.sh .
COPY run-chainweb-node.sh .
COPY initialize-db.sh .
COPY chainweb.yaml .
COPY check-health.sh .
RUN chmod 755 check-reachability.sh run-chainweb-node.sh initialize-db.sh check-health.sh
RUN mkdir -p /data/chainweb-db
RUN mkdir -p /root/.local/share/chainweb-node/mainnet01/
RUN ln -s /data/chainweb-db /root/.local/share/chainweb-node/mainnet01/0

STOPSIGNAL SIGTERM
EXPOSE 443
HEALTHCHECK --start-period=5m --interval=1m --retries=5 --timeout=10s CMD ./check-health.sh

CMD ./run-chainweb-node.sh
