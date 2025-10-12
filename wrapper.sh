#!/usr/bin/env bash
set -euo pipefail

DEMO_DIR="$(cd "$(dirname "$0")" && pwd)"
SHARED_DIR="${DEMO_DIR}/demo_shared"
HNDL_DIR="${SHARED_DIR}/tmp"
PCAP="${HNDL_DIR}/1_traffic_demo.pcap"
PCAP_PATH_IN_CONTAINER="/app/tmp/1_traffic_demo.pcap"
SERVER_CONTAINER="toy_server"
TCPDUMP_TIMEOUT="${TCPDUMP_TIMEOUT:-15}"

# create folder
mkdir -p "$SHARED_DIR" "$HNDL_DIR"

# cleanup from previous runs
rm -rf "${HNDL_DIR}"/*

# build image
echo "1) Building docker images..."
docker compose build

# start toy server
echo "2) Starting toy_server (detached)..."
docker compose up -d toy_server

# harvest server public key (wait for it to be created)
echo "3) Waiting for server to create non-empty /app/tmp/server_pub.hex..."
TRIES=0
MAX_TRIES=20
while [ $TRIES -lt $MAX_TRIES ]; do
  if docker exec "$SERVER_CONTAINER" test -s /app/tmp/server_pub.hex >/dev/null 2>&1; then
    docker cp "${SERVER_CONTAINER}:/app/tmp/server_pub.hex" "${HNDL_DIR}/server_pub.hex"
    echo "Server public hex copied to ${HNDL_DIR}/server_pub.hex"
    break
  fi
  TRIES=$((TRIES+1))
  sleep 1
done
if [ $TRIES -ge $MAX_TRIES ]; then
  echo "ERROR: timed out waiting for non-empty /app/tmp/server_pub.hex - show recent server logs:"
  docker logs --tail 200 "$SERVER_CONTAINER"
  exit 1
fi

# -- SSH SERVER ---
echo "4) Starting tcpdump inside server container for ${TCPDUMP_TIMEOUT}s..."

# create folder & install tcpdump
docker exec -u root "$SERVER_CONTAINER" mkdir -p /app/tmp
docker exec -u root "$SERVER_CONTAINER" bash -c "if ! command -v tcpdump >/dev/null 2>&1; then apt-get update >/dev/null && apt-get install -y tcpdump >/dev/null; fi"

# start tcpdump
docker exec -u root "$SERVER_CONTAINER" bash -c "timeout ${TCPDUMP_TIMEOUT}s tcpdump -i any -s 0 -w ${PCAP_PATH_IN_CONTAINER} tcp port 2222 or tcp port 22 & echo tcpdump_started" >/dev/null
sleep 1

# -- SSH CLIENT ---
echo "5) Running client container (will send payload to server)..."

# send payload
docker compose up --no-deps --no-build --exit-code-from toy_client toy_client || true

# wait for tcpdump to finish writing
WAIT=0
MAX_WAIT=$((TCPDUMP_TIMEOUT + 5))
echo "6) Waiting for pcap to appear inside container..."
while [ $WAIT -lt $MAX_WAIT ]; do
  if docker exec "$SERVER_CONTAINER" test -s "$PCAP_PATH_IN_CONTAINER" >/dev/null 2>&1; then
    echo "PCAP found inside container."
    break
  fi
  WAIT=$((WAIT+1))
  sleep 1
done
if [ $WAIT -ge $MAX_WAIT ]; then
  echo "ERROR: pcap not found or empty inside container after ${MAX_WAIT}s. Listing /app/tmp for debugging:"
  docker exec "$SERVER_CONTAINER" ls -l /app/tmp || true
  docker logs --tail 200 "$SERVER_CONTAINER"
  exit 1
fi

# copy pcap
echo "7) Copying pcap from container to host: ${PCAP}"
docker cp "${SERVER_CONTAINER}:${PCAP_PATH_IN_CONTAINER}" "${PCAP}"
echo "8) PCAP saved on host:"
ls -lh "$PCAP" || true

# Extraction: run inside container
echo "9) Running extractor inside container..."
docker exec --user root "$SERVER_CONTAINER" python /app/extract_harvest.py "${PCAP_PATH_IN_CONTAINER}" 2222 \
  --out-client /app/tmp/harvested_client_pub.hex --out-cipher /app/tmp/harvested_cipher.hex || {
    echo "ERROR: extractor failed inside container. Container logs:"
    docker logs --tail 200 "$SERVER_CONTAINER"
    exit 1
  }

# pull harvested files to host
echo "10) Copying harvested files and server private key to host..."
docker cp "${SERVER_CONTAINER}:/app/tmp/harvested_client_pub.hex" "${HNDL_DIR}/harvested_client_pub.hex" || true
docker cp "${SERVER_CONTAINER}:/app/tmp/harvested_cipher.hex" "${HNDL_DIR}/harvested_cipher.hex" || true
docker cp "${SERVER_CONTAINER}:/app/tmp/server_priv.pem" "${HNDL_DIR}/server_priv.pem" || true
echo "Files in $HNDL_DIR:"
ls -l "$HNDL_DIR" || true

# decrypt
echo "11) Running decrypt (attacker simulation) on host..."
python3 "${SHARED_DIR}/decrypt.py" "${HNDL_DIR}/server_priv.pem" "${HNDL_DIR}/harvested_client_pub.hex" "${HNDL_DIR}/harvested_cipher.hex"

echo ">>> Demo finished. Check $HNDL_DIR for artifacts."
