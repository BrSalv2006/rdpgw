ARG GO_VERSION=1.26
ARG DEBIAN_VERSION=trixie

# ==========================================
# Builder Stage
# ==========================================
FROM golang:${GO_VERSION}-${DEBIAN_VERSION} AS builder

RUN apt-get update && apt-get install -y --no-install-recommends \
        gcc \
        libc6-dev \
        libpam0g-dev \
        pkg-config \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src

COPY go.mod ./
RUN go mod download

COPY . .

RUN go mod tidy && \
    CGO_ENABLED=0 GOOS=linux go build -trimpath -o /out/rdpgw ./cmd/rdpgw && \
    CGO_ENABLED=1 GOOS=linux go build -trimpath -o /out/rdpgw-auth ./cmd/auth

# ==========================================
# Runtime Stage
# ==========================================
FROM debian:${DEBIAN_VERSION}-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
        libpam0g \
        libpam-modules \
        libpam-modules-bin \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/rdpgw

COPY --from=builder /out/rdpgw .
COPY --from=builder /out/rdpgw-auth .
COPY dev/docker/rdpgw-pam /etc/pam.d/rdpgw

RUN cat > /start.sh <<'EOF'
#!/bin/sh
/opt/rdpgw/rdpgw-auth &
sleep 2
exec /opt/rdpgw/rdpgw
EOF

RUN chmod +x /opt/rdpgw/rdpgw /opt/rdpgw/rdpgw-auth /start.sh

EXPOSE 443

ENTRYPOINT ["/start.sh"]
