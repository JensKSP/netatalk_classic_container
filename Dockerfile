FROM alpine AS netatalk_base

RUN apk add --no-cache db db-utils libgcrypt openssl zlib \
	avahi linux-pam gnu-libiconv libtirpc rpcsvc-proto \
	libintl cups krb5-libs \
	acl shadow bash perl tzdata libldap

FROM netatalk_base AS netatalk_build

RUN apk add --no-cache make gcc git flex bison \
	autoconf automake libtool patch pkgconfig \
	linux-headers gdb file \
	libc-dev db-dev libgcrypt-dev openssl-dev \
	zlib-dev avahi-dev linux-pam-dev \
	gnu-libiconv-dev rpcsvc-proto-dev libtirpc-dev \
	cups-dev acl-dev krb5-dev openldap-dev

RUN apk add --no-cache musl-dbg openssl-dbg

ENV PKG_CONFIG_PATH=/opt/netatalk/lib/pkgconfig
ENV LDFLAGS="-L/opt/netatalk/lib -Wl,-rpath,/opt/netatalk/lib"
ENV CPPFLAGS="-I/opt/netatalk/include -I/usr/include/tirpc"
# ENV CFLAGS="-g"

RUN mkdir -p /usr/src/openslp \
&& cd /usr/src/openslp \
&& git clone --progress --depth 1 \
#	https://github.com/openslp-org/openslp.git . -b master \
	https://github.com/JensKSP/openslp.git . -b fix_parallel_build

RUN cd /usr/src/openslp/openslp && ./autogen.sh \
	&& mkdir ../build && cd ../build && ../openslp/configure \
		--enable-slpv2-security --prefix=/opt/netatalk \
	&& make -j$(nproc) && make install

COPY ./patches/netatalk.patch /usr/src/patches/netatalk.patch

RUN mkdir -p /usr/src/netatalk-code \
&& cd /usr/src/netatalk-code \
&& git clone --progress --depth 1 \
	https://github.com/Netatalk/Netatalk . -b branch-netatalk-2-2 \
&& patch -Np1 < /usr/src/patches/netatalk.patch

RUN cd /usr/src/netatalk-code && ./bootstrap \
	&& CPPFLAGS="$CPPFLAGS -DNEED_RQUOTA" \
		LDFLAGS="$LDFLAGS -ltirpc" \
	./configure --prefix=/opt/netatalk \
		--disable-afs \
		--enable-ddp \
		--enable-srvloc \
		--enable-a2boot \
		--enable-timelord \
		--enable-systemd \
		--enable-cups \	
		--with-shadow \
		--enable-overwrite \
		--enable-dropkludge \
		--enable-logfile \
		--enable-krb4-uam \
		--enable-krbV-uam \
		--with-acls \
		--enable-force-uidgid \
	&& make -j$(nproc) && make install

FROM netatalk_base AS netatalk
COPY --from=netatalk_build /opt/netatalk /opt/netatalk

COPY ./etc/netatalk /opt/netatalk/etc/netatalk
ENV PATH="/container/scripts:/opt/netatalk/sbin:/opt/netatalk/bin:${PATH}"

RUN touch /var/log/messages \
	&& afppasswd -c

COPY ./scripts /container/scripts
RUN find /container/scripts -type f -exec chmod +x {} \;

CMD [ "/container/scripts/netatalk.sh" ]

HEALTHCHECK CMD ["/container/scripts/docker-healthcheck.sh"]
ENTRYPOINT ["/container/scripts/entrypoint.sh"]

EXPOSE 201
EXPOSE 201/udp
EXPOSE 202
EXPOSE 202/udp
EXPOSE 204
EXPOSE 204/udp
EXPOSE 206
EXPOSE 206/udp
EXPOSE 427
EXPOSE 427/udp
EXPOSE 548
EXPOSE 548/udp
EXPOSE 1935
EXPOSE 5353/udp
