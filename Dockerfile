# syntax=docker/dockerfile:experimental

# Run as
#
# --ulimit nofile=64000:64000

FROM ubuntu:18.04

# install prerequesites
RUN apt-get update && apt-get install -y librocksdb-dev curl xxd openssl

# Install chainweb applications
WORKDIR /chainweb
# RUN curl -Ls "https://github.com/kadena-io/chainweb-node/releases/download/1.6/chainweb-1.6.ghc-8.6.5.ubuntu-18.04.16a279de.tar.gz" | tar -xzC "/chainweb/"
RUN curl -Ls "https://kadena-cabal-cache.s3.amazonaws.com/chainweb.8.8.2.ubuntu-18.04.bb0c0ee0.tar.gz" | tar -xzC "/chainweb/"

COPY check-reachability.sh .
COPY run-chainweb-node.sh .
COPY initialize-db.sh .
COPY chainweb.yaml .
RUN chmod 755 check-reachability.sh run-chainweb-node.sh initialize-db.sh

STOPSIGNAL SIGINT
EXPOSE 443
HEALTHCHECK --start-period=5m --interval=1m --retries=5 --timeout=10s \
    CMD curl -fsLk "https://localhost/chainweb/0.0/mainnet01/cut" || exit 1

CMD ./run-chainweb-node.sh

