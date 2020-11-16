FROM alpine:3.12.1 as builder
COPY build.sh /tmp/build.sh
RUN /tmp/build.sh

FROM alpine:3.12.1
COPY --from=builder /tmp/frr.tar.gz /tmp/frr.tar.gz
RUN tar xfv /tmp/frr.tar.gz -C / && \
    rm /tmp/frr.tar.gz && \
    apk add --no-cache json-c libcap readline
