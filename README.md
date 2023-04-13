# zerotier-docker
Enterprise-ready Zerotier docker container

## Motivation

This version uses only RHEL Universal Base Image as platform, [tini init system](https://github.com/krallin/tini) and official [rustup](https://www.rust-lang.org/tools/install) to build and run image, assuring complete compatibility with RedHat environment. It also bring some optimization in container size and forced PID1-handler provided by tini.

### Why not use docker --init?

Some system like [VyOS](https://docs.vyos.io/en/equuleus/configuration/container/index.html) does not support `--init` flat addition.

## Build status: [![Docker Repository on Quay](https://quay.io/repository/zenithtecnologia/zerotier-docker/status "Docker Repository on Quay")](https://quay.io/repository/zenithtecnologia/zerotier-docker)

## How to use:

This container is compatible with [Zerotier official image](https://github.com/zerotier/ZeroTierOne/blob/dev/README.docker.md) way to use.
