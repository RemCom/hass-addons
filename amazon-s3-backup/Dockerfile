ARG BUILD_FROM=ghcr.io/hassio-addons/base:15.0.6
# hadolint ignore=DL3006
FROM ${BUILD_FROM}

# Set shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Setup base
ARG AWSCLI_VERSION=1.32.39
# hadolint ignore=DL3003,DL3042
RUN \
  apk add --no-cache --virtual .build-dependencies \
    autoconf=2.71-r2 \
    automake=1.16.5-r2 \
    build-base=0.5-r3 \
    linux-headers=6.5-r0 \
    musl-dev=1.2.4_git20230717-r4 \
    py3-pip=23.3.1-r0 \
    python3-dev=3.11.6-r1 \
  \
  && apk add --no-cache \
    py3-setuptools=68.2.2-r0 \
    python3=3.11.6-r1 \
  \
  && pip3 install awscli==${AWSCLI_VERSION} \
  \
  && apk del --no-cache --purge .build-dependencies \
  && rm -f -r \
    /tmp/*  \
   \
  && chmod a+x /run.sh

# Copy root filesystem
COPY rootfs /

CMD [ "/run.sh" ]

# Build arguments
ARG BUILD_ARCH
ARG BUILD_DATE
ARG BUILD_DESCRIPTION
ARG BUILD_NAME
ARG BUILD_REF
ARG BUILD_REPOSITORY
ARG BUILD_VERSION

# Labels
LABEL \
    io.hass.name="${BUILD_NAME}" \
    io.hass.description="${BUILD_DESCRIPTION}" \
    io.hass.arch="${BUILD_ARCH}" \
    io.hass.type="addon" \
    io.hass.version=${BUILD_VERSION} \
    maintainer="Remco van Essen <dev@remcom.dev>" \
    org.opencontainers.image.title="${BUILD_NAME}" \
    org.opencontainers.image.description="${BUILD_DESCRIPTION}" \
    org.opencontainers.image.vendor="RemCom's Home Assistant Addons" \
    org.opencontainers.image.authors="Remco van Essen <dev@remcom.dev>" \
    org.opencontainers.image.licenses="MIT" \
    org.opencontainers.image.url="https://addons.community" \
    org.opencontainers.image.source="https://github.com/${BUILD_REPOSITORY}" \
    org.opencontainers.image.documentation="https://github.com/${BUILD_REPOSITORY}/blob/main/README.md" \
    org.opencontainers.image.created=${BUILD_DATE} \
    org.opencontainers.image.revision=${BUILD_REF} \
    org.opencontainers.image.version=${BUILD_VERSION}