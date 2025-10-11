#!/usr/bin/env python3
import sys, os, re
from scapy.all import rdpcap, TCP, Raw, IP
import argparse

HEX_LINE_RE = re.compile(r'^[0-9a-fA-F]+\r?\n?$', re.M)

def is_likely_payload(text):
    lines = [l.strip() for l in text.splitlines() if l.strip()]
    if len(lines) < 3:
        return False
    if not all(re.fullmatch(r'[0-9a-fA-F]+', l) for l in lines[:3]):
        return False
    if len(lines[0]) < 128:
        return False
    if len(lines[1]) < 16 or len(lines[1]) > 48:
        return False
    if len(lines[2]) < 32:
        return False
    return True

def reassemble_stream(pkts, server_port):
    streams = {}
    for p in pkts:
        if not p.haslayer(TCP):
            continue
        if not p.haslayer(Raw):
            continue
        ip = p[IP]
        tcp = p[TCP]
        key = (ip.src, ip.dst, tcp.sport, tcp.dport)
        streams.setdefault(key, b'')
        streams[key] += bytes(p[Raw].load)
    candidates = []
    for (src,dst,sport,dport), data in streams.items():
        if sport == server_port or dport == server_port:
            try:
                txt = data.decode('utf-8', errors='ignore')
            except:
                txt = ''
            candidates.append((src,dst,sport,dport,txt))
    return candidates

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('pcap', help='pcap file path')
    parser.add_argument('port', type=int, help='server TCP port used by demo (e.g. 2222)')
    parser.add_argument('--out-client', default='harvested_client_pub.hex')
    parser.add_argument('--out-cipher', default='harvested_cipher.hex')
    args = parser.parse_args()

    if not os.path.exists(args.pcap):
        print("pcap not found:", args.pcap); sys.exit(1)

    pkts = rdpcap(args.pcap)
    streams = reassemble_stream(pkts, args.port)

    for src,dst,sport,dport,txt in streams:
        if not txt:
            continue
        norm = txt.replace('\r\n','\n').replace('\r','\n')
        lines = [l.strip() for l in norm.split('\n') if l.strip()]
        if len(lines) < 3:
            continue
        first3 = "\n".join(lines[:3]) + "\n"
        if is_likely_payload(first3):
            client_pub = lines[0]
            nonce = lines[1]
            cipher = lines[2]
            with open(args.out_client, 'w') as f:
                f.write(client_pub + "\n")
            with open(args.out_cipher, 'w') as f:
                f.write(nonce + "\n" + cipher + "\n")
            print("Found matching stream from", src, sport, "->", dst, dport)
            print("Wrote:", args.out_client, args.out_cipher)
            return
    print("No matching payload found in pcap.")
    sys.exit(2)

if __name__ == '__main__':
    main()
