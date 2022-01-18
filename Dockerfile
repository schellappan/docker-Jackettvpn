# Jackett, OpenVPN and WireGuard, JackettVPN
FROM alpine:3.13 as JacketUIs

# Download Jackett
RUN apk --no-cache add curl jq \
    && mkdir -p /opt/jackett \
    && echo "Getting Jackett.." \
    && JACKETT_VERSION=$(curl -sX GET "https://api.github.com/repos/Jackett/Jackett/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/') \
    && curl -o /opt/Jackett.Binaries.LinuxAMDx64.tar.gz -L "https://github.com/Jackett/Jackett/releases/download/${JACKETT_VERSION}/Jackett.Binaries.LinuxAMDx64.tar.gz" \
    && tar -xzf /opt/Jackett.Binaries.LinuxAMDx64.tar.gz -C /opt \
    && rm -f /opt/Jackett.Binaries.LinuxAMDx64.tar.gz

FROM ubuntu:20.04

VOLUME /data
VOLUME /config

COPY --from=JacketUIs /opt/Jackett /opt/Jackett

ENV DEBIAN_FRONTEND noninteractive
ENV XDG_DATA_HOME="/config" \
XDG_CONFIG_HOME="/config"

WORKDIR /opt

RUN usermod -u 99 nobody

# Make directories
RUN mkdir -p /blackhole /config/Jackett /etc/jackett

# Install WireGuard and other dependencies some of the scripts in the container rely on.
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y \
    dumb-init openvpn wireguard-tools privoxy \
    tzdata dnsutils iputils-ping ufw openssh-client icu-devtools\
    moreutils dos2unix kmod git jq curl wget unrar unzip bc zlib1g\
    && rm -rf /tmp/* /var/tmp/* /var/lib/apt/lists/* \
    && groupmod -g 1000 users \
    && useradd -u 911 -U -d /config -s /bin/false abc \
    && usermod -G users abc

VOLUME /blackhole /config

ADD openvpn/ /etc/openvpn/
ADD jackett/ /etc/jackett/
ADD scripts /etc/scripts/

RUN chmod +x /etc/jackett/*.sh /etc/jackett/*.init /etc/openvpn/*.sh /opt/Jackett/jackett

ENV OPENVPN_USERNAME=**None** \
    OPENVPN_PASSWORD=**None** \
    OPENVPN_PROVIDER=**None** \
    GLOBAL_APPLY_PERMISSIONS=true \
    CREATE_TUN_DEVICE=true \
    ENABLE_UFW=false \
    UFW_ALLOW_GW_NET=false \
    UFW_EXTRA_PORTS= \
    UFW_DISABLE_IPTABLES_REJECT=false \
    PUID= \
    PGID= \
    PEER_DNS=true \
    PEER_DNS_PIN_ROUTES=true \
    DROP_DEFAULT_ROUTE= \
    LOG_TO_STDOUT=false \
    HEALTH_CHECK_HOST=google.com \
    SELFHEAL=false

HEALTHCHECK --interval=1m CMD /etc/scripts/healthcheck.sh

# Add labels to identify this image and version
ARG REVISION
# Set env from build argument or default to empty string
ENV REVISION=${REVISION:-""}
LABEL org.opencontainers.image.source=https://github.com/schellappan/docker-JackettVPN
LABEL org.opencontainers.image.revision=$REVISION

# Compatability with https://hub.docker.com/r/willfarrell/autoheal/
LABEL autoheal=true

# Expose port and run
EXPOSE 9117

CMD ["dumb-init", "/etc/openvpn/start.sh"]
