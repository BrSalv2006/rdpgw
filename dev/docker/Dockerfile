ARG GO_VERSION=1.26
ARG ALPINE_VERSION=3.21

# ==========================================
# Builder Stage
# ==========================================
FROM golang:${GO_VERSION}-alpine${ALPINE_VERSION} AS builder

RUN apk add --no-cache gcc musl-dev linux-pam-dev pkgconf

WORKDIR /src

COPY go.mod go.sum ./
RUN go mod download

COPY . .

RUN go mod tidy && \
    CGO_ENABLED=0 GOOS=linux go build -trimpath -o /out/rdpgw ./cmd/rdpgw && \
    CGO_ENABLED=1 GOOS=linux go build -trimpath -o /out/rdpgw-auth ./cmd/auth

# ==========================================
# Runtime Stage
# ==========================================
FROM alpine:${ALPINE_VERSION}

RUN apk add --no-cache linux-pam ca-certificates

WORKDIR /opt/rdpgw

COPY --from=builder /out/rdpgw .
COPY --from=builder /out/rdpgw-auth .
COPY dev/docker/rdpgw-pam /etc/pam.d/rdpgw

RUN chmod +x /opt/rdpgw/rdpgw /opt/rdpgw/rdpgw-auth && \
    cat > /start.sh <<'EOF'
#!/bin/sh
/opt/rdpgw/rdpgw-auth &
sleep 2
exec /opt/rdpgw/rdpgw
EOF
chmod +x /start.sh

EXPOSE 443

ENTRYPOINT ["/start.sh"]
