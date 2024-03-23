FROM alpine:latest

RUN apk add --no-cache \
  openssh \
  bash

COPY sshd_config /etc/ssh/sshd_config

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
