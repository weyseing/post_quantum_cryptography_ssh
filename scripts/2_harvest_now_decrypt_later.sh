#!/bin/bash
# harvest_now_decrypt_later.sh

# pcap file path (example: /tmp/hndl_pqc.pcap)
PCAP="$1" 

# create folder
OUTDIR="/tmp/hndl_$(basename $PCAP .pcap)"
mkdir -p "$OUTDIR"

# full SSH block
tshark -r "$PCAP" -Y ssh -V > "$OUTDIR/ssh_verbose.txt"

# supported KEYEX algo
grep -i "kex_algorithms string" "$OUTDIR/ssh_verbose.txt" \
  | sed -E 's/.*kex_algorithms string: //' \
  | awk '
    /ext-info-c/ { print "[CLIENT] " $0; next }
    /ext-info-s/ { print "[SERVER] " $0; next }
    { print "[UNKNOWN] " $0 }
  ' > "$OUTDIR/kex_algo.txt"

# chosen KEYEX algo
client_algos=$(grep -i "ext-info-c" /tmp/hndl_traffic_classic/ssh_verbose.txt | sed -E 's/.*string: //; s/,ext-info-c.*//')
server_algos=$(grep -i "ext-info-s" /tmp/hndl_traffic_classic/ssh_verbose.txt | sed -E 's/.*string: //; s/,ext-info-s.*//')

for algo in $(echo "$client_algos" | tr ',' ' '); do
  if echo "$server_algos" | grep -qw "$algo"; then
    echo "Negotiated KEX algorithm: $algo"
    break
  fi
done

# # 3) Extract KEX host key blocks (public key + signature)
# egrep -n "KEX host key|EdDSA public key|Host signature data|Host signature type" "$OUTDIR/ssh_verbose.txt" > "$OUTDIR/hostkey_blocks.txt"
# # You can open ssh_verbose.txt and copy the hex blocks referenced here.

# # 4) Extract ephemeral public values (classical)
# egrep -i "ECDH client's ephemeral public key|ECDH server's ephemeral public key|ephemeral public" "$OUTDIR/ssh_verbose.txt" > "$OUTDIR/ephemeral_publics.txt"

# # 5) Dump raw frame hex for frames that contain 'Key Exchange' (useful to find PQ KEM bytes)
# tshark -r "$PCAP" -x -Y 'ssh && frame contains "Key Exchange (method:"' > "$OUTDIR/kex_frames_hex.txt"

# # 6) Dump raw frame hex for application data after the last observed KEX time (approx)
# # Find last Key Exchange frame number
# LAST_KEX_FRAME=$(egrep -n "Key Exchange \\(method:" "$OUTDIR/ssh_verbose.txt" | tail -n1 | cut -d: -f1 || true)
# # fallback: if not found, just dump all SSH frames
# if [ -n "$LAST_KEX_FRAME" ]; then
#   # map the verbose line number back to frame number is manual — so also dump all ssh frame hex as fallback
#   tshark -r "$PCAP" -x -Y 'ssh && tcp.port == 22' > "$OUTDIR/all_ssh_frames_hex.txt"
# else
#   tshark -r "$PCAP" -x -Y 'ssh && tcp.port == 22' > "$OUTDIR/all_ssh_frames_hex.txt"
# fi

echo "Extracts saved in $OUTDIR"
