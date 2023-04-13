# vim: ft=dockerfile

FROM registry.access.redhat.com/ubi9:latest as build

ARG zt_version=1.10.6

WORKDIR /tmp
RUN mkdir /zt-rpm \
    && dnf -y install make gcc gcc-c++ git clang openssl openssl-devel systemd https://download.rockylinux.org/pub/rocky/9/AppStream/x86_64/os/Packages/r/rpmdevtools-9.5-1.el9.noarch.rpm \
    && curl https://sh.rustup.rs -sSf | sh -s -- -y --quiet --profile minimal \
    && git clone --quiet --depth=1 --branch ${zt_version} https://github.com/zerotier/ZeroTierOne.git 2>&1 > /dev/null \
    && cd ZeroTierOne \
    && git log --pretty=oneline -n1 \
    && make redhat \
    && find /root/rpmbuild/RPMS -type f -name "*$(rpm --eval '%{_arch}')*.rpm" -print0 | xargs -0 -I {} mv -v {} /zt-rpm/ \
    && rm -rf /var/cache/yum /var/lib/dnf

FROM registry.access.redhat.com/ubi9-minimal:latest

COPY --from=build /zt-rpm/* /zt-rpm/
COPY entrypoint.sh.release /entrypoint.sh

RUN rpm --nodeps --noscripts -Uvh /zt-rpm/*.rpm \
    && microdnf -y install $(rpm -qpR /zt-rpm/*.rpm | grep -v [\(\)\/] | grep -v systemd ) \
    && rm -rf /var/lib/zerotier-one \
    && chmod 755 /entrypoint.sh \
    && rm -rf /var/cache/yum /var/lib/dnf

HEALTHCHECK --interval=1s CMD bash /healthcheck.sh

CMD []
ENTRYPOINT ["/entrypoint.sh"]

