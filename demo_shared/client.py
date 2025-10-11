#!/usr/bin/env python3
import socket, binascii, time, os
from cryptography.hazmat.primitives.asymmetric import ec
from cryptography.hazmat.primitives import serialization, hashes
from cryptography.hazmat.primitives.kdf.hkdf import HKDF
from cryptography.hazmat.primitives.ciphers.aead import AESGCM

HOST = "toy_server"
PORT = 2222

# create ephemeral ECDH keypair
client_priv = ec.generate_private_key(ec.SECP256R1())
client_pub = client_priv.public_key().public_bytes(
    encoding=serialization.Encoding.X962,
    format=serialization.PublicFormat.UncompressedPoint
)

# client epheremeral public key
print("=== CLIENT (lab) ===")
print("Client ephemeral public (hex):", binascii.hexlify(client_pub).decode())

# server epheremeral public key
time.sleep(1.0)
server_pub_hex = None
try:
    with open("/app/server_pub.hex","r") as f:
        server_pub_hex = f.read().strip()
except Exception as e:
    print("server_pub.hex not found in /app; please ensure server printed and wrote it:", e)
    raise SystemExit("server_pub.hex not found; aborting client.")
server_pub_bytes = binascii.unhexlify(server_pub_hex)
server_pub = ec.EllipticCurvePublicKey.from_encoded_point(ec.SECP256R1(), server_pub_bytes)

# derive shared session key
shared = client_priv.exchange(ec.ECDH(), server_pub)
hkdf = HKDF(algorithm=hashes.SHA256(), length=32, salt=None, info=b"toy-ssh-session")
session_key = hkdf.derive(shared)
print("Derived session key (client-side) (hex):", binascii.hexlify(session_key).decode())

# encrypt message (simulate SSH payload)
aesgcm = AESGCM(session_key)
nonce = os.urandom(12)
plaintext = b"TOY-SSH: secret server file contents"
ciphertext = aesgcm.encrypt(nonce, plaintext, associated_data=None)

# send client_pub, nonce, ciphertext as hex lines
client_pub_hex = binascii.hexlify(client_pub).decode()
nonce_hex = binascii.hexlify(nonce).decode()
ciphertext_hex = binascii.hexlify(ciphertext).decode()
print("\nSending to server (this will be captured by your network capture):")
print("- client_pub_hex:", client_pub_hex)
print("- nonce_hex:", nonce_hex)
print("- ciphertext_hex:", ciphertext_hex)

# simple TCP client to send to server
s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.connect((HOST, PORT))
payload = "\n".join([client_pub_hex, nonce_hex, ciphertext_hex])
s.sendall(payload.encode())
s.close()
print("SSH Client done.")
