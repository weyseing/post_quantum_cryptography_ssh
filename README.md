# Set SSH Key Exchange Algo
- **Configure settings**
```shell
# set for classic
echo "KexAlgorithms sntrup761x25519-sha512@openssh.com" >> /etc/ssh/sshd_config` 
# set for PQC
echo "KexAlgorithms curve25519-sha256@libssh.org" >> /etc/ssh/sshd_config 
# restart SSH
/usr/sbin/sshd -D
# check settings 
sshd -T | grep -i kex 
```

# Capture SSH Traffic
- **Access to SSH Client**
    - `docker exec -it ssh_client bash`
- **Classic key exchange**
    - `tcpdump -i any -s 0 -w /tmp/hndl_classic.pcap`
    - `ssh root@ssh_server_classic`
- **PQC key exchange**
    - `tcpdump -i any -s 0 -w /tmp/hndl_pqc.pcap`
    - `ssh root@ssh_server_pqc`

