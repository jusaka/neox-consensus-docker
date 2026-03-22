#!/bin/bash
set -euo pipefail

DATADIR="/data"
GENESIS="/genesis.json"

# ─── Validate required files ────────────────────────────────
if [ ! -f "$DATADIR/keystore/"* ] 2>/dev/null; then
  echo "❌ No keystore found in $DATADIR/keystore/"
  echo "   Mount your wallet keystore file there."
  exit 1
fi

if [ ! -f "$DATADIR/password.txt" ]; then
  echo "❌ Missing $DATADIR/password.txt (wallet unlock password)"
  exit 1
fi

# Wallet address: from env or auto-detect from keystore filename
if [ -z "${WALLET_ADDRESS:-}" ]; then
  # Keystore filename format: UTC--...--<address>
  WALLET_ADDRESS=$(ls "$DATADIR/keystore/" | head -1 | grep -oE '[0-9a-fA-F]{40}$' || true)
  if [ -z "$WALLET_ADDRESS" ]; then
    echo "❌ Cannot auto-detect wallet address. Set WALLET_ADDRESS env var."
    exit 1
  fi
fi
WALLET_ADDRESS="0x${WALLET_ADDRESS#0x}"
echo "🔑 Wallet: $WALLET_ADDRESS"

# ─── Init genesis (idempotent) ──────────────────────────────
if [ ! -d "$DATADIR/geth/chaindata" ]; then
  echo "📦 Initializing genesis..."
  geth init --state.scheme hash --datadir "$DATADIR" "$GENESIS"
fi

# ─── Init antimev keystore if not present ───────────────────
if [ ! -d "$DATADIR/antimev" ]; then
  echo "🛡️ Initializing antimev keystore..."
  PASS=$(cat "$DATADIR/password.txt")
  # antimev init expects password + confirmation on stdin
  printf '%s\n%s\n' "$PASS" "$PASS" | geth --datadir "$DATADIR" antimev init "$WALLET_ADDRESS"
fi

# ─── ZK-DKG R1CS/PK files (optional for consensus) ─────────
DKG_FLAGS=""
if [ -d "$DATADIR/r1cs" ] && [ -d "$DATADIR/pk" ]; then
  echo "🔐 ZK-DKG files detected, enabling..."
  DKG_FLAGS="--dkg.one-msg-r1cs $DATADIR/r1cs/one_message.ccs \
    --dkg.two-msg-r1cs $DATADIR/r1cs/two_message.ccs \
    --dkg.seven-msg-r1cs $DATADIR/r1cs/seven_message.ccs \
    --dkg.one-msg-pk $DATADIR/pk/one_message.pk \
    --dkg.two-msg-pk $DATADIR/pk/two_message.pk \
    --dkg.seven-msg-pk $DATADIR/pk/seven_message.pk"
fi

# ─── External IP ────────────────────────────────────────────
NAT_FLAG="--nat extip:${EXTERNAL_IP:-0.0.0.0}"

# ─── Bootnodes ──────────────────────────────────────────────
BOOTNODES="${BOOTNODES:-enode://92eec46dd8b67ea8d8999defe0bf2b43d4c4802ed42a430843fec97dafbdc9128849261bdf1a940d431fc61f06a1317f5fc7c0386e18a9bbf951d0ccd8bf4f98@34.42.6.58:30303,enode://f289fb5c83ed39cf7d7aff2727afe70bf7951222c4a9aaef7bcbceef9fd0b53e4b6c9c0e08a50774dfd50d93e83b977932e4780934d379a6a0ac10cc44c6cfdb@34.87.188.162:30303}"

# ─── Launch ─────────────────────────────────────────────────
echo "🚀 Starting Neo X consensus node..."
exec geth \
  --networkid 47763 \
  $NAT_FLAG \
  --port 30303 \
  --discovery.port 30303 \
  --mine \
  --miner.pending.feeRecipient "$WALLET_ADDRESS" \
  --unlock "$WALLET_ADDRESS" \
  --password "$DATADIR/password.txt" \
  --antimev.password "$DATADIR/password.txt" \
  $DKG_FLAGS \
  --authrpc.port 8551 \
  --identity "neox-consensus" \
  --maxpeers ${MAX_PEERS:-50} \
  --syncmode full \
  --gcmode ${GC_MODE:-archive} \
  --datadir "$DATADIR" \
  --bootnodes "$BOOTNODES" \
  --http --http.addr 0.0.0.0 --http.port 8545 --http.vhosts "*" --http.corsdomain '*' \
  --http.api eth,net,txpool,web3,dbft \
  --ws --ws.addr 0.0.0.0 --ws.port 8546 --ws.api eth,net,web3 --ws.origins '*' \
  --allow-insecure-unlock \
  --verbosity ${VERBOSITY:-3} \
  "$@"
