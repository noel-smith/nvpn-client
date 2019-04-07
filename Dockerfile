FROM alpine:latest

RUN apk --no-cache --no-progress add \
  openvpn tini bash jq curl

COPY openvpn.sh /usr/bin/
COPY download_opvn.sh /usr/bin/

ENTRYPOINT ["/sbin/tini", "--", "/usr/bin/openvpn.sh"]