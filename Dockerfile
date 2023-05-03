# vim: ft=dockerfile

FROM registry.redhat.io/ubi9:latest as build

ARG zt_version=1.10.6

WORKDIR /tmp
RUN mkdir /zt-root \
    && dnf -y install make gcc gcc-c++ git clang openssl openssl-devel systemd rpmdevtools \
    && curl https://sh.rustup.rs -sSf | sh -s -- -y --quiet --profile minimal \
    && git clone --depth=1 --branch ${zt_version} https://github.com/zerotier/ZeroTierOne.git 2>&1 > /dev/null \
    && cd ZeroTierOne \
    && git log --pretty=oneline -n1 \
    && make redhat \
    && find /root/rpmbuild/RPMS -type f -name "*$(rpm --eval '%{_arch}')*.rpm" -print0 | xargs -0 -I {} dnf install --installroot /zt-root {} --releasever 9 --setopt install_weak_deps=false --nodocs -y \
    && dnf --installroot /zt-root clean all \
    && rm -rf /var/cache/yum /var/lib/dnf /zt-root/var/cache/yum /zt-root/var/lib/dnf /zt-root/var/lib/rpm*

FROM registry.redhat.io/ubi9-minimal:latest

ADD https://raw.githubusercontent.com/zerotier/ZeroTierOne/${zt_version}/entrypoint.sh.release /entrypoint.sh
COPY --from=build /zt-root /

HEALTHCHECK --interval=1s CMD bash /healthcheck.sh

ENV TINI_VERSION v0.19.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini
ENTRYPOINT ["/tini", "--"]

CMD ["/entrypoint.sh"]
