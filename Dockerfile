# vim: ft=dockerfile

FROM registry.redhat.io/ubi9:latest as build

ARG zt_version

WORKDIR /tmp

ADD patches /patches

# Since this image will be discarded in the end, nobody cares about tons of RUN statement except build cache :)

RUN curl -sSL -o /entrypoint.sh https://raw.githubusercontent.com/zerotier/ZeroTierOne/dev/entrypoint.sh.release \
    && chmod 0755 /entrypoint.sh

RUN dnf -y install make gcc gcc-c++ git patch clang openssl openssl-devel libstdc++ libstdc++-devel libstdc++-static glibc-devel \
    && dnf clean all \
    && rm -rf /var/cache/yum

RUN curl https://sh.rustup.rs -sSf | sh -s -- -y --quiet --profile minimal #rhel

RUN git clone --depth=1 --branch ${zt_version} https://github.com/zerotier/ZeroTierOne.git 2>&1 > /dev/null \
    && cd ZeroTierOne \
    && git log --pretty=oneline -n1 \
    && rm -rf .git \
    && patchlistall=$(ls -1 /patches/all-*.patch 2> /dev/null || true) \
    && if [ -n "${patchlistall}" ]; then for patch in "${patchlistall}"; do echo "Applying all versions patch ${patch}" ; patch -p0 -i ${patch} ; done ; fi \
    && patchlistver=$(ls -1 /patches/${zt_version}-*.patch 2> /dev/null || true) \
    && if [ -n "${patchlistver}" ]; then for patch in "${patchlist}"; do echo "Applying version ${zt_version} patch ${patch}" ; patch -p0 -i ${patch} ; done ; fi \
    && make LDFLAGS="-static-libstdc++" -j $(nproc --ignore=1) one \
    && mkdir /zt-root \
    && DESTDIR=/zt-root make install \
    && rm -rfv /zt-root/var/lib/zerotier-one \
    && strip /zt-root/usr/sbin/zerotier-one \
    && cd .. \
    && rm -rf ZeroTierOne

RUN mkdir curl \
    && cd curl \
    && curl -sSL https://api.github.com/repos/curl/curl/releases/latest \
    | grep .\*browser_download_url.\*tar.gz\"\$ \
    | cut -d \" -f 4 \
    | xargs curl -sSL \
    | tar -xvz \
    && cd curl-* \
    && ./configure --without-libpsl --disable-dict --disable-gopher -disable-imap --disable-ldap \
       --disable-ldaps --disable-mqtt --disable-ntlm --disable-pop3 --disable-rtsp --disable-smb \
       --disable-smtp --disable-tftp --disable-tls-srp --disable-websockets --without-brotli --without-libssh \
       --disable-shared --enable-ipv6 --with-openssl \
    && make -j$(nproc --ignore=1) V=1 \ 
    && strip src/curl \
    && ./src/curl -V \
    && mv -v ./src/curl /curl \
    && cd .. \
    && rm -rf curl

RUN git clone --depth=1 --branch=v0.2.0 https://github.com/openSUSE/catatonit.git 2>&1 > /dev/null \
    && cd catatonit \
    && dnf -y install autoconf automake libtool \
    && dnf clean all \
    && rm -rf /var/cache/yum \
    && ./autogen.sh \
    && ./configure \
    && make -j$(nproc --ignore=1) \
    && strip catatonit \
    && cd .. \
    && mv catatonit/catatonit /catatonit \
    && rm -rf catatonit

RUN dnf -y --installroot=/zt-root --setopt=install_weak_deps=False install redhat-release openssl openssl-libs zlib glibc glibc-common glibc-minimal-langpack

# --- end of build --- #

FROM scratch

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
COPY --from=build --chmod=0755 /entrypoint.sh /entrypoint.sh
COPY --from=build --chmod=0755 /catatonit /catatonit

HEALTHCHECK --interval=5s --start-period=30s --retries=5 CMD bash /healthcheck.sh

ENTRYPOINT ["/catatonit", "--", "/entrypoint.sh"]
