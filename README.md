# Quick Setup

*[NOTE: the instructions in previous version of this README file initialized
that database slightly different. If you have database volume that was created with
such a version, you can continue to use it by mounting it via
`-v chainweb-db:/data/chainweb-db` or just by using the old instructions]*

1.  *(Skip this step if you run the Chainweb node in data center.)* Log into your
    router and configure port forwarding for port 443 to your computer.

2.  Make sure that your firewall allows incoming connection on port 443.

3.  Initialize database *(optional but saves several hours of db synchronization
    on node startup.)*:

    ```sh
    docker run -ti --rm -v chainweb-data:/data kadena/chainweb-node /chainweb/initialize-db.sh
    ```

4.  Start Chainweb node:

    ```sh
    docker run -d -p 1848:1848 -p 443:443 -v chainweb-data:/data kadena/chainweb-node
    ```

For explanations and additional configuration options (like, for instance, using
an alternate port) keep reading.

# Running a Chainweb Node as Docker Container

**A Chainweb node must be reachable from the public internet**. It needs a
public IP address and port. If you run the node from a data center, usually, you
only have to ensure that it can be reached on the default port 443. You can use
the following shell command to start the node.

```sh
docker run -d -p 1848:1848 -p 443:443 kadena/chainweb-node
```

If you are running the node from a local network with NAT (network address
translation), which is the case for most home networks, you'll have to configure
port forwarding in your router.

Using a different port is possible, too. For that the public port number must be
provided the Chainweb node in the environment.

```sh
docker run -d -p 1848:1848 -p 1789:1789 -e "CHAINWEB_PORT=1789" kadena/chainweb-node
```

More options to configure the node are described at the bottom of this document.

Above command starts the node with an empty Chainweb database. It will take
about 12-24 hours until the node has "caught up" with the network, joined
consensus, and can be used for mining and processing transactions.

The startup time can be shortened by initializing the node with a pre-computed
database. This is strongly encouraged and described further down in this
document.

# Initialize Chainweb Database

When the container is started for the first time it has to synchronize and
rebuild the Chainweb database from the P2P network. This can take a long time.
Currently, as of 2020-03-28, this takes about twelve hours for a node in a well
connected data center.

The container includes script for synchronizing a pre-build database, which
currently, as of 2020-03-28, involves downloading about 4.5GB of data from an S3
container.

### Database within Chainweb node container

The following shell commands initialize a docker container with a database and
create a new image from it.

```sh
docker run -ti --name initialize-chainweb-db kadena/chainweb-node /chainweb/initialize-db.sh
docker commit `docker ps -a -f 'name=initialize-chainweb-db' -q` chainweb-node-with-db
docker rm initialize-chainweb-db
```

Once the database is initialized the image can be used to run a Chainweb node as
follows:

```sh
docker run \
    --detach \
    --publish 1848:1848 \
    --publish 443:443 \
    --name chainweb-node \
    chainweb-node-with-db \
    /chainweb/run-chainweb-node.sh
```

# Persistent the Chainweb database (outside of container)

When the Chainweb database is stored in the container it is lost when the
container is deleted. This could, for instance, happen when a new version of
Chainweb is released and the node is upgraded to the new version.

It is therefore recommended to store the Chainweb database outside the container
on a docker volume (preferred method) or in the file system of the host system.

```sh
# 1. Initialize a database that is persisted on a docker volume
docker run -ti --rm \
    --mount type=volume,source=chainweb-data,target=/data \
    kadena/chainweb-node \
    /chainweb/initialize-db.sh

# 2. Use the database volume with a Chainweb node
docker run \
    --detach \
    --publish 1848:1848 \
    --publish 443:443 \
    --name chainweb-node \
    --mount type=volume,source=chainweb-data,target=/data \
    kadena/chainweb-node
```

Alternatively a bind mount can be used to persist the database in the file
system of the host.

# Enable Mining API

The private mining API is enabled by providing the public key of a miner as
environment variable in the container using the `-e` option of Docker's `run`
command. Optionally, the miner account name can be given, too. If the account
name is omitted the public key is used as account name.

Only a single miner with a single is supported. The key predicate is `keys-all`.

The following example provides a public miner key and an account name:

```sh
docker run \
    --detach \
    --publish 1848:1848 \
    --publish 443:443 \
    -e "MINER_KEY=26a9285cd8db34702cfef27a5339179b5a26373f03dd94e2096b0b3ba6c417da" \
    -e "MINER_ACCOUNT=merle" \
    --name chainweb-node \
    --mount type=volume,source=chainweb-db,target=/root/.local/share/chainweb-node/mainnet01/0/ \
    kadena/chainweb-node
```

Please refer to the official [chainweb-miner](https://github.com/kadena-io/chainweb-miner)
for a further information of how to use the mining API to mine on Chainweb. The
official reference implementation does not support mining devices that are
powerful enough to competitively mine on the Kadena Mainnet. Links to alternate
mining software can be found
[here](https://kadena-io.github.io/kadena-docs/Public-Chain-Docs/#start-mining).

# Verifying database consistency

TODO

# Running the test suite

TODO

# Technical Details

This Docker image runs a chainweb-node using the public IP address of the host
with self-signed certificates. It supports a single mining key. For many use
cases this is sufficient.

For more complex production setups it is recommended to clone the repository,
edit the configuration file within the Docker container, and create an custom
image.

When a public domain name is used instead of a domain name, we recommend to use
docker compose to run [certbot]() in a different container and share the
certificates using docker volumes.

### Commands:

* `/chainweb/run-chainweb-node.sh`
* `/chainweb/initialize-db.sh`
* `/chainweb/check-reachability.sh`
* `/chainweb/check-health.sh`

### File System

*   Database directory: `/root/.local/share/chainweb-node/mainnet01/0`
*   Chainweb configuration file: `/chainweb/chainweb.yaml`

### Available Configuration Options

*   `CHAINWEB_PORT`: the network port that is used by the Chainweb node.
    The port that is used internally in the container *must* match the port that
    is used publicly. A appropriate port mapping must be passed to the `docker
    run` command, e.g. `-p 443:443`. (default: `443`)

*   `CHAINWEB_BOOTSTRAP_NODE`: a Chainweb node that is used to check the
    connectivity of the container before starting the node. (default:
    `us-w1.chainweb.com`)

*   `LOGLEVEL`: the log-level that is used by the Chainweb node. (default: `warn`).

*   `CHAINWEB_HOST`: the public IP address of the node. (default: automatically
    detected)

*   `MINER_KEY`: the public key of the miner. If this is empty or unset
    mining is disabled. Only a single key is supported with key predicate
    `keys-all`.

*   `MINER_ACCOUNT`: the mining account for the miner key. If unset or empty
    the `MINER_KEY` is also used as account name.

*   TODO:
    *    running a node with a DNS domain name
    *    option for setting the block gas limit
    *    option for enabled the header stream
    *    option for enabling the Rosetta API
    *    explain how to overwrite the configuration file

Here is an example for how to use these settings:

```sh
docker run \
    --detach \
    --publish 1848:1848 \
    --publish 1789:1789 \
    --name chainweb-node \
    --env "CHAINWEB_PORT=1789" \
    --env "CHAINWEB_BOOTSTRAP_NODE=fr2.chainweb.com" \
    --env "LOGLEVEL=warn" \
    kadena/chainweb-node
```

