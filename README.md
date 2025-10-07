# SSH Process

### Transport Layer Protocol: -
- **Key Exchange algorithm:** SSH Server & Client aligned for Key Exchange algo
- **Shared Secret (K):** 
    - SSH Client generate temporary **random number a** and calculates a **public value A** to send to the server.
    - SSH Server generates temporary **random number b** and calculates a **public value B** to send to the client.
    - They both calculate **shared secret, (K)**. Client calculates `(B^{a} (mod p))`. Server calculates `(A^{b} (mod p))`. The result is the same: `(K=g^{ab} (mod p))`.
- **Server authentication** to check if valid server host
    - Server send public host key to client (first time only)
    - Both client & server compute hash (H) the handshake data
    - Server generate signature from hash (H) with private host key
    - Client verify signature from hash (H) with public host key `First saved to (~/.ssh/known_hosts)`
- **Encryption channel** started after session key is established from Shared Secret (K)


### User Authentication Protocol: -
- **Password auth:**
    - SSH Client encrypt the password via Session key
    - SSH Server decrypt the password via Session key to check user's password
- **Public Key auth:**
    - SSH Client requests authentication with its public key
    - SSH Server checks if the public key is allowed (~/.ssh/authorized_keys)
    - SSH Client signs a blob including session ID + request using its private key
    - SSH Server verifies the signature using the client’s public key

### Connection Protocol: -
- This support for `SHELL`, `COMMAND` and `SFTP`
- **Client:** You type uname -a.
- **Encryption:** Your SSH client encrypts "uname -a" using the symmetric session key.
- **Transmission:** The encrypted packet, along with its MAC, travels over the network.
- **Server:** The SSH server receives the packet, verifies its MAC, decrypts it using the same session key, and executes the command.
- **Server response:** The server receives the command output, encrypts it, generates a new MAC, and sends it back to the client.
- **Client display:** Your client receives the packet, verifies its MAC, decrypts it, and displays the output on your terminal. 


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

