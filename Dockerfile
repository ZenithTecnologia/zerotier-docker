# vim: ft=dockerfile

FROM registry.redhat.io/ubi9:latest as build

ARG zt_version=1.10.6

WORKDIR /tmp
RUN mkdir /zt-rpm \
    && dnf -y install make gcc gcc-c++ git clang openssl openssl-devel systemd rpmdevtools \
    && curl https://sh.rustup.rs -sSf | sh -s -- -y --quiet --profile minimal \
    && git clone --quiet --depth=1 --branch ${zt_version} https://github.com/zerotier/ZeroTierOne.git 2>&1 > /dev/null \
    && cd ZeroTierOne \
    && git log --pretty=oneline -n1 \
    && make redhat \
    && find /root/rpmbuild/RPMS -type f -name "*$(rpm --eval '%{_arch}')*.rpm" -print0 | xargs -0 -I {} mv -v {} /zt-rpm/ \
    && rm -rf /var/cache/yum /var/lib/dnf

FROM registry.redhat.io/ubi9-minimal:latest

COPY --from=build /zt-rpm/* /zt-rpm/
COPY entrypoint.sh.release /entrypoint.sh

RUN rpm --nodeps --noscripts -Uvh /zt-rpm/*.rpm \
    && microdnf -y install $(rpm -qpR /zt-rpm/*.rpm | grep -v [\(\)\/] | grep -v systemd ) \
    && rm -rf /var/lib/zerotier-one \
    && chmod 755 /entrypoint.sh \
    && rm -rf /var/cache/yum /var/lib/dnf

HEALTHCHECK --interval=1s CMD bash /healthcheck.sh

ENV TINI_VERSION v0.19.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini
ENTRYPOINT ["/tini", "--"]

CMD ["/entrypoint.sh"]
