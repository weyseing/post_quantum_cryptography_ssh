#!/bin/bash
# harvest_now_decrypt_later.sh

# create folder
OUTDIR="/tmp/hndl"
mkdir -p "$OUTDIR"

# file path
PCAP_CLASSIC="/tmp/capture_traffic/1_traffic_classic.pcap"
PCAP_PQC="/tmp/capture_traffic/1_traffic_pqc.pcap"
SSH_CLASSIC="/tmp/capture_traffic/2_ssh_classic_verbose.txt"
SSH_PQC="/tmp/capture_traffic/2_ssh_pqc_verbose.txt"
PCAP_VERBOSE_CLASSIC="$OUTDIR/1_pcap_verbose_classic.txt"
PCAP_VERBOSE_PQC="$OUTDIR/1_pcap_verbose_pqc.txt"

# full SSH block
tshark -r "$PCAP_CLASSIC" -Y ssh -V > "$PCAP_VERBOSE_CLASSIC"
tshark -r "$PCAP_PQC" -Y ssh -V > "$PCAP_VERBOSE_PQC"

# supported KEYEX algo
grep -i "kex_algorithms string" "$PCAP_VERBOSE_CLASSIC" \
  | sed -E 's/.*kex_algorithms string: //' \
  | awk '
    /ext-info-c/ { print "[CLIENT] " $0; next }
    /ext-info-s/ { print "[SERVER] " $0; next }
    { print "[UNKNOWN] " $0 }
  ' > "$OUTDIR/2_supported_algo_classic.txt"

grep -i "kex_algorithms string" "$PCAP_VERBOSE_PQC" \
  | sed -E 's/.*kex_algorithms string: //' \
  | awk '
    /ext-info-c/ { print "[CLIENT] " $0; next }
    /ext-info-s/ { print "[SERVER] " $0; next }
    { print "[UNKNOWN] " $0 }
  ' > "$OUTDIR/2_supported_algo_pqc.txt"

# chosen KEYEX algo
grep "debug1: kex: algorithm:" "$SSH_CLASSIC" | awk '{print $4}' > "$OUTDIR/3_chosen_algo_classic.txt"
grep "debug1: kex: algorithm:" "$SSH_PQC" | awk '{print $4}' > "$OUTDIR/3_chosen_algo_pqc.txt"

