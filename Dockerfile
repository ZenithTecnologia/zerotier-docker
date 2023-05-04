# vim: ft=dockerfile

FROM registry.redhat.io/ubi9:latest as build

# Since this image will be discarded in the end, nobody cares about tons of RUN statement

ARG zt_version

WORKDIR /tmp
RUN mkdir /zt-root \
    && dnf -y install make gcc gcc-c++ git clang openssl openssl-devel libstdc++ libstdc++-devel libstdc++-static glibc-static

RUN curl https://sh.rustup.rs -sSf | sh -s -- -y --quiet --profile minimal

RUN git clone --depth=1 --branch ${zt_version} https://github.com/zerotier/ZeroTierOne.git 2>&1 > /dev/null \
    && cd ZeroTierOne \
    && git log --pretty=oneline -n1 

RUN cd ZeroTierOne \
    && make LDFLAGS="-static-libgcc -static-libstdc++" -j $(nproc --ignore=1) one \
    && DESTDIR=/zt-root make install \
    && rm -rfv /zt-root/var/lib/zerotier-one

FROM registry.redhat.io/ubi9/openssl:latest

ARG zt_version

LABEL io.k8s.description "This container runs Zerotier - a smart programmable Ethernet switch for planet Earth."
LABEL io.k8s.display-name "zerotier"
LABEL maintainer "Zenith Tecnologia <dev@zenithtecnologia.com.br>"
LABEL name "zerotier"
LABEL summary "ZeroTier - a smart programmable Ethernet switch for planet Earth."
LABEL url "https://github.com/ZenithTecnologia/zerotier-docker"
LABEL org.zerotier.version ${zt_version}

COPY --from=build /zt-root /

ENV TINI_VERSION v0.19.0
ADD --chmod=0755 https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
ADD --chmod=0755 https://raw.githubusercontent.com/zerotier/ZeroTierOne/${zt_version}/entrypoint.sh.release /entrypoint.sh

HEALTHCHECK --interval=1s CMD bash /healthcheck.sh

ENTRYPOINT ["/tini", "--", "/entrypoint.sh"]
