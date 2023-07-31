# vim: ft=dockerfile

FROM registry.redhat.io/ubi9:latest as build

ARG zt_version
ARG curl_version=8.0.1

WORKDIR /tmp

# Since this image will be discarded in the end, nobody cares about tons of RUN statement except build cache :)

RUN dnf -y install make gcc gcc-c++ git clang openssl openssl-devel libstdc++ libstdc++-devel libstdc++-static glibc-static

RUN curl https://sh.rustup.rs -sSf | sh -s -- -y --quiet --profile minimal #rhel

RUN git clone --depth=1 --branch ${zt_version} https://github.com/zerotier/ZeroTierOne.git 2>&1 > /dev/null \
    && cd ZeroTierOne \
    && git log --pretty=oneline -n1 

RUN cd ZeroTierOne \
    && make LDFLAGS="-static-libgcc -static-libstdc++" -j $(nproc --ignore=1) one \
    && mkdir /zt-root \
    && DESTDIR=/zt-root make install \
    && rm -rfv /zt-root/var/lib/zerotier-one

RUN mkdir curl \
    && cd curl \
    && curl -O https://curl.se/download/curl-${curl_version}.tar.gz \
    && tar -xvzf curl-${curl_version}.tar.gz \
    && cd curl-${curl_version} \
    && LDFLAGS="-static" PKG_CONFIG="pkg-config --static" ./configure --disable-shared --enable-static --disable-ldap --enable-ipv6 --without-ssl \
    && make -j$(nproc --ignore=1) V=1 LDFLAGS="-static -all-static" \ 
    && strip src/curl \
    && ./src/curl -V \
    && mv -v ./src/curl /curl

# --- end of build --- #

FROM registry.redhat.io/ubi9/openssl:latest

ARG quay_expiration=never

LABEL io.k8s.description "This container runs Zerotier - a smart programmable Ethernet switch for planet Earth."
LABEL io.k8s.display-name "zerotier"
LABEL maintainer "Zenith Tecnologia <dev@zenithtecnologia.com.br>"
LABEL name "zerotier"
LABEL summary "ZeroTier - a smart programmable Ethernet switch for planet Earth."
LABEL url "https://github.com/ZenithTecnologia/zerotier-docker"
LABEL org.zerotier.version ${zt_version}
LABEL quay.expires-after ${quay_expiration}

COPY --from=build /zt-root /
COPY --from=build --chmod=0755 /curl /usr/bin/curl

ENV TINI_VERSION v0.19.0
ADD --chmod=0755 https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini

ARG zt_version
#ADD --chmod=0755 https://raw.githubusercontent.com/zerotier/ZeroTierOne/${zt_version}/entrypoint.sh.release /entrypoint.sh
# 1.10.6: From dev until joining get fixed 
ADD --chmod=0755 https://raw.githubusercontent.com/zerotier/ZeroTierOne/dev/entrypoint.sh.release /entrypoint.sh

HEALTHCHECK --interval=5s --start-period=30s --retries=5 CMD bash /healthcheck.sh

ENTRYPOINT ["/tini", "--", "/entrypoint.sh"]
