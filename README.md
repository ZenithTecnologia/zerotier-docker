# zerotier-docker
Enterprise-ready Zerotier docker container

## Status

[![Build Zerotier Dev](https://github.com/ZenithTecnologia/zerotier-docker/actions/workflows/build-dev.yml/badge.svg)](https://github.com/ZenithTecnologia/zerotier-docker/actions/workflows/build-dev.yml)

## Motivation

This version uses only RHEL Universal Base Image as platform, [tini init system](https://github.com/krallin/tini) and official [rustup](https://www.rust-lang.org/tools/install) to build and run image, assuring complete compatibility with RedHat environment. It also bring some optimization in container size and forced PID1-handler provided by tini.

### Why not use docker `--init`?

Some system like [VyOS](https://docs.vyos.io/en/equuleus/configuration/container/index.html) does not support `--init` flat addition.

## How to use

This container is compatible with [Zerotier official image](https://github.com/zerotier/ZeroTierOne/blob/dev/README.docker.md) way to use. To pull the image you can use `podman pull quay.io/zenithtecnologia/zerotier-docker:latest` or `docker pull quay.io/zenithtecnologia/zerotier-docker:latest`

A Debian image is also available with some optimizations at `quay.io/zenithtecnologia/zerotier-docker:latest-debian`

Images with sha-tag have a expiration time set to 90 days to keep house clean.

## Notes about building

Build requires podman because entitlement keys must be mounted on container. Also, requires to be build on licenced RHEL.
