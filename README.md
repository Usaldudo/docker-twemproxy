[![FOSSA Status](https://app.fossa.com/api/projects/git%2Bgithub.com%2FUsaldudo%2Fdocker-twemproxy.svg?type=shield)](https://app.fossa.com/projects/git%2Bgithub.com%2FUsaldudo%2Fdocker-twemproxy?ref=badge_shield)

# Overview

A tiny (<7mb) Docker image of twemproxy server (AKA nutcracker).

Based on minimalistic Alpine Linux.

Forked from <https://github.com/malexer/docker-twemproxy> to add sentinel from [ifwe/twemproxy](https://github.com/ifwe/twemproxy/tree/0.5.2-tmg19).

# Reason

I was looking for a small image to use as a sidecar twemproxy container (Redis based).

There are several twemproxy images already present on a Docker Hub but most of them are >100mb size or contain extra services which I was trying to avoid (reviewed in 2018). Some of them also does not support graceful shutdown of twemproxy.

This image is targeting:

1. Reusable baseimage which can be easily configured by the ENV (see "Usage" section).
2. Small size. Only required dependencies, nothing from the build step.
3. Link to the repo with Dockerfile to understand what is inside.
4. Graceful shutdown of twemproxy (send SIGINT).

# Quickstart

Just provide a list of Redis servers as ENV.

i.e. if you want to redirect to three Redis instances, create this custom Dockerfile:

```dockerfile
FROM ghcr.io/usaldudo/tweamproxy:0.5.1

ENV REDIS_SERVERS 127.0.1.1:6379:1,127.0.1.2:6379:1,127.0.1.3:6379:1
```

This will generate default Twemproxy config on container start:

```yaml
pool:
    listen: 0.0.0.0:6380
    hash: fnv1a_64
    distribution: ketama
    redis: true
    auto_eject_hosts: true
    timeout: 2000
    server_retry_timeout: 5000
    server_failure_limit: 1
    server_connections: 40
    preconnect: true
    servers:
        - 127.0.1.1:6379:1
        - 127.0.1.2:6379:1
        - 127.0.1.3:6379:1
```

if you want to use sentinel, use `REDIS_SENTINEL_SERVERS` variable :

```dockerfile
FROM ghcr.io/usaldudo/tweamproxy:0.5.1

ENV REDIS_SERVERS "127.0.1.1:6379:1 server1,127.0.1.2:6379:1 server2,127.0.1.3:6379:1 server3"
ENV REDIS_SENTINEL_SERVERS "127.0.0.1:26379:1,127.0.0.1:26380:1,127.0.0.1:26381:1"
```

This will generate default Twemproxy config on container start:

```yaml
pool:
    listen: 0.0.0.0:6380
    hash: fnv1a_64
    distribution: ketama
    redis: true
    auto_eject_hosts: true
    timeout: 2000
    server_retry_timeout: 5000
    server_failure_limit: 1
    server_connections: 40
    preconnect: true
    servers:
        - 127.0.1.1:6379:1 server1
        - 127.0.1.2:6379:1 server2
        - 127.0.1.3:6379:1 server3
    sentinels:
        - 127.0.0.1:26379:1
        - 127.0.0.1:26380:1
        - 127.0.0.1:26381:1
```

# Advanced configuration

There are two ways to use this image as a baseimage:

1. Redefine ENV variables (only some is supported).
2. Provide your own entire config.

## Redefine ENV variables

Twemproxy's config will be generated by this template:

```yaml
pool:
    listen: 0.0.0.0:${LISTEN_PORT}
    hash: fnv1a_64
    distribution: ketama
    redis: true
    auto_eject_hosts: ${AUTO_EJECT_HOSTS}
    timeout: ${TIMEOUT}
    server_retry_timeout: ${SERVER_RETRY_TIMEOUT}
    server_failure_limit: ${SERVER_FAILURE_LIMIT}
    server_connections: ${SERVER_CONNECTIONS}
    preconnect: ${PRECONNECT}
    servers:
        <LIST of SERVERS from ${REDIS_SERVERS}>
    sentinels:
        <LIST of SERVERS from ${REDIS_SENTINEL_SERVERS}>
```

Default values are:

| ENV                  | Value                             |
| -------------------- | --------------------------------- |
| LISTEN_PORT          | 6380                              |
| REDIS_SERVERS        | 127.0.0.1:6378:1,127.0.0.1:6379:1 |
| AUTO_EJECT_HOSTS     | true                              |
| TIMEOUT              | 2000                              |
| SERVER_RETRY_TIMEOUT | 5000                              |
| SERVER_FAILURE_LIMIT | 1                                 |
| SERVER_CONNECTIONS   | 40                                |
| PRECONNECT           | true                              |

Redefine at least `REDIS_SERVERS`.

Config will be generated on container start, so you can provide these ENVs in docker-compose or as command-line to `docker run`.

Note: in case if `LISTEN_PORT` is redefined, you should duplicate this port in EXPOSE in your custom Dockerfile as well.

## Custom config

Create you full config and copy it to the image to `/etc/nutcracker.conf`.

Init script will detect custom config and skip generating it from ENV.

yourconfig.conf:

```yaml
staging:
    listen: 0.0.0.0:11380
    hash: fnv1a_64
    distribution: ketama
    servers:
        - server1:6379:1
        - server2:6379:1
```

Dockerfile:

```dockerfile
FROM ghcr.io/usaldudo/twemproxy:latest

COPY yourconfig.conf /etc/nutcracker.conf

EXPOSE 11380
```

## License

[![FOSSA Status](https://app.fossa.com/api/projects/git%2Bgithub.com%2FUsaldudo%2Fdocker-twemproxy.svg?type=large)](https://app.fossa.com/projects/git%2Bgithub.com%2FUsaldudo%2Fdocker-twemproxy?ref=badge_large)
