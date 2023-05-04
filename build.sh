#!/bin/sh -e

zt_version_latest=$(git describe --tags `git rev-list --tags --max-count=1`)
zt_version=$(git describe --abbrev=0)
zt_is_latest=0

# Podman Required - Docker does not support volume on build

BUILDAH_FORMAT=docker podman buildx build -v /etc/pki/entitlement:/run/secrets/etc-pki-entitlement:ro -t quay.io/zenithtecnologia/zerotier-docker:${zt_version} --build-arg zt_version=${zt_version} .
BUILDAH_FORMAT=docker podman buildx build -t quay.io/zenithtecnologia/zerotier-docker:${zt_version}-debian --build-arg zt_version=${zt_version} -f Dockerfile.debian .

podman push quay.io/zenithtecnologia/zerotier-docker:${zt_version}
podman push quay.io/zenithtecnologia/zerotier-docker:${zt_version}-debian

if [[ ${zt_version} == ${zt_version_latest} ]]; then
	podman tag quay.io/zenithtecnologia/zerotier-docker:${zt_version} quay.io/zenithtecnologia/zerotier-docker:latest
	podman tag quay.io/zenithtecnologia/zerotier-docker:${zt_version}-debian quay.io/zenithtecnologia/zerotier-docker:latest-debian
	podman push quay.io/zenithtecnologia/zerotier-docker:latest
	podman push quay.io/zenithtecnologia/zerotier-docker:latest-debian
fi
