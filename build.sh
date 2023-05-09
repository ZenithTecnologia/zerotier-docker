#!/bin/sh -e

zt_version_latest=$(git describe --tags `git rev-list --tags --max-count=1`)
zt_version=$(git describe --abbrev=0)
zt_dev_sha=$(git ls-remote https://github.com/zerotier/ZeroTierOne.git --head refs/heads/dev | awk '{print $1}')

# Podman Required - Docker does not support volume on build

grep FROM Dockerfile* | awk -F'FROM ' '{ print $2 }' | awk '{ print $1 }' | uniq | xargs podman pull

BUILDAH_FORMAT=docker podman buildx build --cache-ttl=24h -t quay.io/zenithtecnologia/zerotier-docker:dev -t quay.io/zenithtecnologia/zerotier-docker:${zt_dev_sha} --build-arg zt_version=dev .
BUILDAH_FORMAT=docker podman buildx build --cache-ttl=24h -t quay.io/zenithtecnologia/zerotier-docker:${zt_version} --build-arg zt_version=${zt_version} .
BUILDAH_FORMAT=docker podman buildx build --cache-ttl=24h -t quay.io/zenithtecnologia/zerotier-docker:${zt_version}-debian --build-arg zt_version=${zt_version} -f Dockerfile.debian .

podman push quay.io/zenithtecnologia/zerotier-docker:dev
podman push quay.io/zenithtecnologia/zerotier-docker:${zt_dev_sha}
podman push quay.io/zenithtecnologia/zerotier-docker:${zt_version}
podman push quay.io/zenithtecnologia/zerotier-docker:${zt_version}-debian

if [[ ${zt_version} == ${zt_version_latest} ]]; then
	podman tag quay.io/zenithtecnologia/zerotier-docker:${zt_version} quay.io/zenithtecnologia/zerotier-docker:latest
	podman tag quay.io/zenithtecnologia/zerotier-docker:${zt_version}-debian quay.io/zenithtecnologia/zerotier-docker:latest-debian
	podman push quay.io/zenithtecnologia/zerotier-docker:latest
	podman push quay.io/zenithtecnologia/zerotier-docker:latest-debian
fi
