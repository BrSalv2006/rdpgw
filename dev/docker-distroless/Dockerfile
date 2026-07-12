ARG GO_VERSION=1.26

FROM golang:${GO_VERSION} AS builder

ENV CGO_ENABLED=0

WORKDIR /src

COPY go.mod go.sum ./
RUN go mod download

COPY . .

RUN go mod tidy && \
    go build -trimpath -o /out/rdpgw ./cmd/rdpgw

FROM gcr.io/distroless/static:nonroot

WORKDIR /config
COPY --from=builder /out/rdpgw /rdpgw

CMD ["/rdpgw"]
