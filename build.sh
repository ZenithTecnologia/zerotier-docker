#!/bin/sh

zt_version_latest=$(git describe --tags `git rev-list --tags --max-count=1`)
zt_version=$(git describe --abbrev=0)
zt_is_latest=0

# Podman Required - Docker does not support volume on build

BUILDAH_FORMAT=docker podman buildx build -v /etc/pki/entitlement:/etc/pki/entitlement:ro -t quay.io/zenithtecnologia/zerotier-docker:${zt_version} --build-arg VERSION=${zt_version} .
podman push quay.io/zenithtecnologia/zerotier-docker:${zt_version}

if [[ ${zt_version} == ${zt_version_latest} ]]; then
	podman tag quay.io/zenithtecnologia/zerotier-docker:${zt_version} quay.io/zenithtecnologia/zerotier-docker:latest
	podman push quay.io/zenithtecnologia/zerotier-docker:latest
fi
