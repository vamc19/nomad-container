FROM ubuntu:21.10 as download
ARG HASHICORP_PGP_FINGERPRINT="C874 011F 0AB4 0511 0D02 1055 3436 5D94 72D7 468F"
ARG NOMAD_VERSION=1.2.6
RUN apt-get update && apt-get install -y \
      wget \
      gnupg \
      unzip \
    && rm -rf /var/lib/apt/lists/* \
    && case "$(arch)" in \
        aarch64) ARCH='arm64' ;; \
        x86_64) ARCH='amd64' ;; \
        *) echo >&2 "error: unsupported architecture" && exit 1 ;; \
      esac \
    && wget https://releases.hashicorp.com/nomad/${NOMAD_VERSION}/nomad_${NOMAD_VERSION}_linux_${ARCH}.zip \
    && wget https://releases.hashicorp.com/nomad/${NOMAD_VERSION}/nomad_${NOMAD_VERSION}_SHA256SUMS \
    && wget https://releases.hashicorp.com/nomad/${NOMAD_VERSION}/nomad_${NOMAD_VERSION}_SHA256SUMS.sig \
    && GNUPGHOME="$(mktemp -d)" \
    && export GNUPGHOME \
    && gpg --keyserver pgp.mit.edu --keyserver keys.openpgp.org --keyserver keyserver.ubuntu.com --recv-keys "${HASHICORP_PGP_FINGERPRINT}" \
    && gpg --batch --verify nomad_${NOMAD_VERSION}_SHA256SUMS.sig nomad_${NOMAD_VERSION}_SHA256SUMS \
    && grep nomad_${NOMAD_VERSION}_linux_${ARCH}.zip nomad_${NOMAD_VERSION}_SHA256SUMS | sha256sum -c \
    && unzip -d /bin nomad_${NOMAD_VERSION}_linux_${ARCH}.zip \
    && chmod +x /bin/nomad \
    && rm -rf "$GNUPGHOME" nomad_${NOMAD_VERSION}_linux_${ARCH}.zip nomad_${NOMAD_VERSION}_SHA256SUMS nomad_${NOMAD_VERSION}_SHA256SUMS.sig

FROM ubuntu:21.10
LABEL maintainer="Vamsi Atluri <vamc19@gmail.com>"

RUN apt-get update && apt-get install -y \
      openssl \
      iproute2 \
      ca-certificates \
      dumb-init \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /var/nomad \
    && mkdir -p /etc/nomad

COPY --from=download /bin/nomad /bin/nomad

VOLUME /var/nomad
EXPOSE 4646 4647 4648 4648/udp

COPY --chmod=755 entrypoint.sh /usr/local/bin/
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

