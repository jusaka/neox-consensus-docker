# Neo X Consensus Node
# Based on bane-labs/go-ethereum v0.5.3
FROM golang:1.24-alpine AS builder

RUN apk add --no-cache gcc musl-dev linux-headers git

WORKDIR /build
RUN git clone --depth 1 --branch v0.5.3 https://github.com/bane-labs/go-ethereum.git .
RUN go mod download
RUN go run build/ci.go install -static ./cmd/geth

# --- Runtime ---
FROM alpine:latest

RUN apk add --no-cache ca-certificates bash curl jq

COPY --from=builder /build/build/bin/geth /usr/local/bin/geth
COPY --from=builder /build/config/genesis_mainnet.json /genesis.json
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# P2P / HTTP-RPC / WS / AuthRPC
EXPOSE 30303 30303/udp 8545 8546 8551

ENTRYPOINT ["/entrypoint.sh"]
