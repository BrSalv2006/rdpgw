# Stage 1: Build binaries
FROM golang:alpine AS deps

WORKDIR /app

# Install build dependencies for PAM, CGO, and glibc toolchain compatibility
RUN apk --no-cache add git gcc musl-dev linux-pam-dev gcompat

# Copy source code
COPY . .

# Ensure modules are tidied, dependencies downloaded, and binaries compiled
RUN go mod tidy && \
    CGO_ENABLED=0 go build -trimpath -ldflags "-s -w" -o /app/bin/rdpgw ./cmd/rdpgw && \
    CGO_ENABLED=1 go build -trimpath -ldflags "-s -w" -o /app/bin/rdpgw-auth ./cmd/auth

# Stage 2: Runtime image
FROM alpine:latest AS runner

WORKDIR /opt/rdpgw

# Install runtime dependencies
RUN apk --no-cache add linux-pam musl tzdata ca-certificates openssl curl && \
    update-ca-certificates && \
    mkdir -p /opt/rdpgw /tmp/rdpgw

# PAM configuration
COPY dev/docker/rdpgw-pam /etc/pam.d/rdpgw

# Copy compiled binaries from builder
COPY --from=deps /app/bin/rdpgw /opt/rdpgw/rdpgw
COPY --from=deps /app/bin/rdpgw-auth /opt/rdpgw/rdpgw-auth

# Copy web templates and assets
COPY cmd/rdpgw/templates /opt/rdpgw/templates
COPY assets /opt/rdpgw/assets

# Copy startup and healthcheck scripts
COPY dev/docker/run.sh /opt/rdpgw/run.sh
COPY dev/docker/healthcheck.sh /opt/rdpgw/healthcheck.sh
RUN chmod +x /opt/rdpgw/run.sh /opt/rdpgw/healthcheck.sh /opt/rdpgw/rdpgw /opt/rdpgw/rdpgw-auth

EXPOSE 443 80

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 CMD /bin/sh /opt/rdpgw/healthcheck.sh

ENTRYPOINT ["/bin/sh", "/opt/rdpgw/run.sh"]
