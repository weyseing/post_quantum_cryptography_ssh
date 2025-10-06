#!/bin/bash
# scripts/start_classic.sh

echo "KexAlgorithms curve25519-sha256@libssh.org" >> /etc/ssh/sshd_config
/usr/sbin/sshd -D
