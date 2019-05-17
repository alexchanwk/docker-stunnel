# Build from source
FROM ubuntu:18.04 AS maker

ARG OPENSSL_URL
ARG STUNNEL_URL

RUN apt-get update && \
    apt-get install -y wget build-essential libssl-dev && \
    mkdir /build && cd /build && mkdir deployables && \
    wget -q ${OPENSSL_URL} && \
    tar -xzf `basename ${OPENSSL_URL}` && rm `basename ${OPENSSL_URL}` && \
    wget -q ${STUNNEL_URL} && \
    tar -xzf `basename ${STUNNEL_URL}` && rm `basename ${STUNNEL_URL}` && \
    apt-get remove -y openssl && \
    cd `basename ${OPENSSL_URL} .tar.gz` && ./config && make && make DESTDIR=/build/deployables install && make install && cd - && \
    export LD_LIBRARY_PATH=/build/deployables/usr/local/lib && \
    cd `basename ${STUNNEL_URL} .tar.gz` && ./configure && make && make install DESTDIR=/build/deployables && cd - && \
    cd deployables && tar -cf deployables.tar usr

# Container image
FROM ubuntu:18.04

COPY --from=maker /build/deployables/deployables.tar /deployables.tar
COPY entrypoint.sh     /entrypoint.sh

RUN apt-get update && \
    apt-get install -y socat && \
    useradd -m -d /home/stunnel stunnel && \
    cd / && tar -xf deployables.tar && rm /deployables.tar && \
    echo /usr/local/lib >> /etc/ld.so.conf && \
    ldconfig && \
    chmod +x /entrypoint.sh

WORKDIR /home/stunnel
USER stunnel

ENTRYPOINT /entrypoint.sh
