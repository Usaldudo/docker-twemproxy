# Build image

FROM docker.io/alpine:3.18 as builder

ENV TWEMPROXY_URL https://github.com/ifwe/twemproxy/archive/refs/tags/0.5.2-tmg19.tar.gz

# Set SHELL flags for RUN commands to allow -e and pipefail
# Rationale: https://github.com/hadolint/hadolint/wiki/DL4006
SHELL ["/bin/ash", "-eo", "pipefail", "-c"]

RUN apk --no-cache add alpine-sdk autoconf automake curl libtool

ARG DEBUG=true

RUN curl -L "$TWEMPROXY_URL" | tar xzf - && \
    TWEMPROXY_DIR=$(find / -maxdepth 1 -iname "twemproxy*" | sort | tail -1) && \
    cd "$TWEMPROXY_DIR" && \
    if [ "$DEBUG" = true ]; then autoreconf -fvi && CFLAGS="-ggdb3 -O0" ./configure --enable-debug=full; else ./configure; fi \
    && make && make install


# Main image

FROM docker.io/alpine:3.18

ENV LISTEN_PORT="6380" \
    REDIS_SERVERS="127.0.0.1:6378:1,127.0.0.1:6379:1" \
    AUTO_EJECT_HOSTS="true" \
    TIMEOUT="2000" \
    SERVER_RETRY_TIMEOUT="5000" \
    SERVER_FAILURE_LIMIT="1" \
    SERVER_CONNECTIONS="40" \
    PRECONNECT="true" \
    HASH="fnv1a_64" \
    DISTRIBUTION="ketama"

RUN apk --no-cache add dumb-init

COPY --from=builder /usr/local/sbin/nutcracker /usr/local/sbin/nutcracker
COPY entrypoint.sh /usr/local/sbin/

ENTRYPOINT ["dumb-init", "--rewrite", "15:2", "--", "entrypoint.sh"]

EXPOSE $LISTEN_PORT
CMD ["nutcracker", "-c", "/etc/nutcracker.conf"]
