#!/bin/bash
set -e

# output folder
OUTDIR=/tmp/capture_traffic
mkdir -p "$OUTDIR"

# --- Classic SSH ---
echo "[+] Capturing Classic SSH handshake..."
tcpdump -i any -s 0 -w "$OUTDIR/1_traffic_classic.pcap" &
TCPDUMP_PID=$!
sleep 1
ssh -vvv root@ssh_server_classic -p 22 \
    -o KexAlgorithms=curve25519-sha256@libssh.org \
    "echo Classic handshake complete" \
    2>"$OUTDIR/2_ssh_classic_verbose.txt"
kill $TCPDUMP_PID
sleep 1

# --- PQC SSH ---
echo "[+] Capturing PQC SSH handshake..."
tcpdump -i any -s 0 -w "$OUTDIR/1_traffic_pqc.pcap" &
TCPDUMP_PID=$!
sleep 1
ssh -vvv root@ssh_server_pqc -p 22 \
    -o KexAlgorithms=sntrup761x25519-sha512@openssh.com \
    "echo PQC handshake complete" \
    2>"$OUTDIR/2_ssh_pqc_verbose.txt"
kill $TCPDUMP_PID

echo "[+] PCAPs saved to $OUTDIR/"
ls -lh "$OUTDIR"
