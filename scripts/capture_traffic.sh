#!/bin/bash
set -e

# Capture Classic SSH
echo "[+] Capturing Classic SSH handshake..."
tcpdump -i any -s 0 -w /tmp/hndl_classic.pcap &
TCPDUMP_PID=$!
sleep 1
ssh root@ssh_server_classic -p 22 -o KexAlgorithms=curve25519-sha256@libssh.org "echo Classic handshake complete"
kill $TCPDUMP_PID
sleep 1

# Capture PQC SSH
echo "[+] Capturing PQC SSH handshake..."
tcpdump -i any -s 0 -w /tmp/hndl_pqc.pcap &
TCPDUMP_PID=$!
sleep 1
ssh root@ssh_server_pqc -p 22 -o KexAlgorithms=sntrup761x25519-sha512@openssh.com "echo PQC handshake complete"
kill $TCPDUMP_PID

# PCAP files
echo "[+] PCAPs saved to /tmp/"
ls -lh /tmp/*.pcap

# HNDL
#  tshark -r /tmp/hndl_classic.pcap -Y ssh -V | egrep -i --color=never -n "kex|kexinit|host key|server host|newkeys|ecdh|kexdh|signature|public key|server key"