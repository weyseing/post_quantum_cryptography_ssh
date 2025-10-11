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
- **Encryption channel** started after **session key** is established from Shared Secret (K)

### User Authentication Protocol: -
- **Password auth:**
    - SSH Client encrypt the password via Session key
    - SSH Server decrypt the password via Session key to check user's password
- **Public Key auth:**
    - SSH Client requests authentication with its public key
    - SSH Server checks if the public key is allowed (~/.ssh/authorized_keys)
    - SSH Client sign a blob (session ID + message) using its private key
    - SSH Server verify the signature using the public key

### Connection Protocol: -
- This support for `SHELL`, `COMMAND` and `SFTP`
- **Client:** You type uname -a.
- **Encryption:** Your SSH client encrypts "uname -a" using the symmetric session key.
- **Transmission:** The encrypted packet, along with its MAC, travels over the network.
- **Server:** The SSH server receives the packet, verifies its MAC, decrypts it using the same session key, and executes the command.
- **Server response:** The server receives the command output, encrypts it, generates a new MAC, and sends it back to the client.
- **Client display:** Your client receives the packet, verifies its MAC, decrypts it, and displays the output on your terminal. 


# Quantum Threat to Cryptography
| Quantum Algorithm | Crypto It Threatens | Effect |
|------------------|------------------|-------|
| **Shor**         | RSA, DH, ECC, Curve25519/X25519, ECDSA, Ed25519 | Recovers private keys → breaks public-key crypto |
| **Grover**       | AES, ChaCha20, SHA-2/3 | Quadratic speedup → halve effective key/hash strength |
| **Kuperberg**    | Some group-based schemes | Subexponential attacks on niche problems |
| **None known**   | PQC: sntrup761x25519, Kyber, NTRU, McEliece, SPHINCS+ | Believed quantum-resistant; attacker cannot compute session keys with known quantum algorithms |


# Set Key Exchange Algo
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