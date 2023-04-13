# vim: ft=dockerfile

FROM registry.access.redhat.com/ubi9:latest as build

WORKDIR /tmp
RUN dnf -y install make gcc gcc-c++ git clang openssl openssl-devel systemd https://dl.rockylinux.org/pub/rocky/9/AppStream/x86_64/os/Packages/r/rpmdevtools-9.5-1.el9.noarch.rpm https://koji.mbox.centos.org/pkgs/packages/rust/1.63.0/1.el8/x86_64/cargo-1.63.0-1.el8.x86_64.rpm https://koji.mbox.centos.org/pkgs/packages/rust/1.63.0/1.el8/x86_64/rust-1.63.0-1.el8.x86_64.rpm https://koji.mbox.centos.org/pkgs/packages/rust/1.63.0/1.el8/x86_64/rust-std-static-1.63.0-1.el8.x86_64.rpm \
    && git clone --depth=1 https://github.com/leleobhz/ZeroTierOne.git \
    && cd ZeroTierOne \
    && make redhat \
    && rm -rf /var/cache/yum /var/lib/dnf

FROM registry.access.redhat.com/ubi9-minimal:latest

COPY --from=build /root/rpmbuild/RPMS/*/*.rpm /tmp/rpm/
COPY entrypoint.sh.release /entrypoint.sh

RUN microdnf -y install openssl \
    && rpm --nodeps --noscripts -Uvh /tmp/rpm/*x86_64*.rpm \
    && rm -rf /var/lib/zerotier-one \
    && chmod 755 /entrypoint.sh \
    && rm -rf /var/cache/yum /var/lib/dnf

HEALTHCHECK --interval=1s CMD bash /healthcheck.sh

CMD []
ENTRYPOINT ["/entrypoint.sh"]

