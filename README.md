# Running a Chainweb Node as Docker Container

**A Chainweb node must be reachable from the public internet**. For that it needs
a public IP address and port. If you run the node from a data center, usually,
you only have to ensure that it can be reached on the default port 443 and use
the following shell command to start the node.

```sh
docker run --detach --ulimit "nofile=65536:65536" --publish 443:443 --name chainweb-node larsk/chainweb-node:latest
```

If you are running the node from a local network with NAT (network address
translation), which is the case for most home networks, you'll have to configure
port forwarding in your router.

Above command starts the node with an empty Chainweb database. It will take
about 12-24 hours until the node has "caught up" with the network, joined
consensus, and can be used for mining and processing transactions.

The startup time can be shortened by initializing the node with a pre-computed
database. This is strongly encouraged and described further down in this
document.

# Available Configuration Options

A few things can be configured via environment variables:

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

Here is an example for how to use these settings:

```sh
docker run \
    --env "CHAINWEB_PORT=1789" \
    --env "CHAINWEB_BOOTSTRAP_NODE=fr2.chainweb.com" \
    --env "LOGLEVEL=warn" \
    --ulimit "nofile=65536:65536" \
    --name chainweb-node \
    --publish 1789:1789 \
    --detach \
    chainweb-node-with-db
```

# Initialize Chainweb Database

When the container is started for the first time it has to synchronize and
rebuild the Chainweb database from the P2P network. This can take a long time.
Currently, as of 2020-03-28, this takes about twelve hours for a node in a well
connected data center.

The container includes script for synchronizing a pre-build database, which
currently, as of 2020-03-28, involves downloading about 4.5GB of data from an S3
container.

You can the following shell commands to to initialize a docker container with a
database and create a new image from it that provides an initialized database.

```sh
docker run -ti --name initialize-chainweb-db larsk/chainweb-node:latest /chainweb/initialize-db.sh
docker commit `docker ps -a -f 'name=initialize-chainweb-db' -q` chainweb-node-with-db
docker rm initialize-chainweb-db
```

Once the database is initialized the container can be used to run a Chainweb node
as follows:

```sh
docker run \
    --ulimit "nofile=65536:65536" \
    --publish 443:443 \
    --detach \
    --name chainweb-node \
    chainweb-node-with-db \
    /chainweb/run-chainweb-node.sh
```

# Persisting the Chainweb Database

By default the Chainweb data is stored in the container and is lost when the
container is deleted. This could, for instance, happen when a new version of
Chainweb is released and the node is upgraded to the new version.

It is therefore recommended to store the Chainweb database outside the container
in the file system of the host system or on a docker volume.

```sh
# 1. Initialize a database that is persisted on a docker volume
docker run -ti --rm \
    --mount type=volume,source=chainweb-db,target=/root/.local/share/chainweb-node/mainnet01/0/ \
    larsk/chainweb-node:latest \
    /chainweb/initialize-db.sh

# 2. Use the database volume with a Chainweb node
docker run \
    --ulimit "nofile=65536:65536" \
    --publish 443:443 \
    --mount type=volume,source=chainweb-db,target=/root/.local/share/chainweb-node/mainnet01/0/ \
    --name chainweb-node \
    --detach \
    larsk/chainweb-node:latest \
```

Alternatively a bind mount can be used to per

# Verifying database consistency

TODO

# Running the test suite

TODO

# Technical Details

### Commands:

* `/chainweb/run-chainweb-node.sh`
* `/chainweb/initialize-db.sh`
* `/chainweb/check-reachability.sh`

### Database Directory Path:

* `/root/.local/share/chainweb-node/mainnet01/0`

