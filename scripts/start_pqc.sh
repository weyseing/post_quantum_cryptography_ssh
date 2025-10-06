#!/bin/bash
# scripts/start_pqc.sh

echo "KexAlgorithms sntrup761x25519-sha512@openssh.com" >> /etc/ssh/sshd_config
/usr/sbin/sshd -D
