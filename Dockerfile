FROM alpine:3.16.0

# Build-time metadata as defined at http://label-schema.org
ARG BUILD_DATE
ARG VCS_REF
ARG VERSION
LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.name="Docker image to provide the net-snmp daemon" \
      org.label-schema.description="Provides snmpd for Flatcar and other small footprint environments without package managers" \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.version=$VERSION \
      org.label-schema.schema-version="1.0"

EXPOSE 161 161/udp

RUN apk add --update --no-cache linux-headers alpine-sdk curl findutils sed
RUN mkdir -p /tmp/snmpd/src
RUN curl -L "https://sourceforge.net/projects/net-snmp/files/net-snmp/5.9.1/net-snmp-5.9.1.tar.gz/download" -o /tmp/snmpd/net-snmp.tgz
RUN tar zxvf /tmp/snmpd/net-snmp.tgz --strip-components=1 -C /tmp/snmpd/src
RUN wget -O /tmp/snmpd/src/config.guess 'https://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.guess;hb=HEAD'
RUN wget -O /tmp/snmpd/src/config.sub 'https://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.sub;hb=HEAD'

WORKDIR /tmp/snmpd/src
RUN find /tmp/snmpd/src -type f -print0 | xargs -0 sed -i 's/\"\/proc/\"\/host_proc/g'
RUN ./configure --prefix=/usr/local --disable-ipv6 --disable-snmpv1 --with-defaults
RUN make
RUN make install

RUN rm -Rf /tmp/snmpd
RUN apk del linux-headers alpine-sdk curl findutils sed

RUN mkdir /etc/snmp

CMD [ "/usr/local/sbin/snmpd", "-f", "-c", "/etc/snmp/snmpd.conf" ]