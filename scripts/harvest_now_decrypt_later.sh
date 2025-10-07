#!/bin/bash
PCAP="$1"   # e.g. /tmp/hndl_pqc.pcap
OUTDIR="/tmp/hndl_extract_$(basename $PCAP .pcap)"
mkdir -p "$OUTDIR"

# 1) Save verbose SSH blocks (human readable)
tshark -r "$PCAP" -Y ssh -V > "$OUTDIR/ssh_verbose.txt"

# 2) Extract KEX algorithm strings
egrep -i "kex_algorithms string" "$OUTDIR/ssh_verbose.txt" > "$OUTDIR/kex_algos.txt"

# 3) Extract KEX host key blocks (public key + signature)
egrep -n "KEX host key|EdDSA public key|Host signature data|Host signature type" "$OUTDIR/ssh_verbose.txt" > "$OUTDIR/hostkey_blocks.txt"
# You can open ssh_verbose.txt and copy the hex blocks referenced here.

# 4) Extract ephemeral public values (classical)
egrep -i "ECDH client's ephemeral public key|ECDH server's ephemeral public key|ephemeral public" "$OUTDIR/ssh_verbose.txt" > "$OUTDIR/ephemeral_publics.txt"

# 5) Dump raw frame hex for frames that contain 'Key Exchange' (useful to find PQ KEM bytes)
tshark -r "$PCAP" -x -Y 'ssh && frame contains "Key Exchange (method:"' > "$OUTDIR/kex_frames_hex.txt"

# 6) Dump raw frame hex for application data after the last observed KEX time (approx)
# Find last Key Exchange frame number
LAST_KEX_FRAME=$(egrep -n "Key Exchange \\(method:" "$OUTDIR/ssh_verbose.txt" | tail -n1 | cut -d: -f1 || true)
# fallback: if not found, just dump all SSH frames
if [ -n "$LAST_KEX_FRAME" ]; then
  # map the verbose line number back to frame number is manual — so also dump all ssh frame hex as fallback
  tshark -r "$PCAP" -x -Y 'ssh && tcp.port == 22' > "$OUTDIR/all_ssh_frames_hex.txt"
else
  tshark -r "$PCAP" -x -Y 'ssh && tcp.port == 22' > "$OUTDIR/all_ssh_frames_hex.txt"
fi

echo "Extracts saved in $OUTDIR"
