#!/usr/bin/env python3
import socket
import binascii
import time
from cryptography.hazmat.primitives.asymmetric import ec
from cryptography.hazmat.primitives import serialization, hashes
from cryptography.hazmat.primitives.kdf.hkdf import HKDF
from cryptography.hazmat.primitives.ciphers.aead import AESGCM
import os

HOST = "0.0.0.0"
PORT = 2222

# create ephemeral ECDH keypair (server side)
server_priv = ec.generate_private_key(ec.SECP256R1())
server_pub = server_priv.public_key().public_bytes(
    encoding=serialization.Encoding.X962,
    format=serialization.PublicFormat.UncompressedPoint
)

# persist server ephemeral private so can later derive key
with open("/app/server_priv.pem", "wb") as f:
    f.write(server_priv.private_bytes(
        encoding=serialization.Encoding.PEM,
        format=serialization.PrivateFormat.PKCS8,
        encryption_algorithm=serialization.NoEncryption()
    ))

# write server ephemeral public so wrapper could read it if needed
with open("/app/server_pub.hex", "wb") as f:
    f.write(binascii.hexlify(server_pub))
print("=== SERVER (lab) ===")
print("Server ephemeral private key saved to /app/server_priv.pem (lab-only)")
print("Server ephemeral public (hex):", binascii.hexlify(server_pub).decode())
print("====================\n")

# simple TCP server to receive client's public and ciphertext
s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.bind((HOST, PORT))
s.listen(1)
print(f"Listening on {HOST}:{PORT} ... (waiting for client)")

conn, addr = s.accept()
with conn:
    print("Connected by", addr)
    data = b''
    # read until socket closed
    while True:
        chunk = conn.recv(65536)
        if not chunk:
            break
        data += chunk

    payload = data.decode().strip().splitlines()
    if len(payload) < 3:
        print("Received payload doesn't contain expected 3 lines, received:", payload)
    else:
        # client public key, nonce, ciphertext
        client_pub_hex = payload[0].strip()
        nonce_hex = payload[1].strip()
        ciphertext_hex = payload[2].strip()

        print("Harvested (from network):")
        print("- Client ephemeral public (hex):", client_pub_hex)
        print("- Nonce (hex):", nonce_hex)
        print("- Ciphertext+tag (hex):", ciphertext_hex)

        client_pub_bytes = binascii.unhexlify(client_pub_hex)
        nonce = binascii.unhexlify(nonce_hex)
        ciphertext = binascii.unhexlify(ciphertext_hex)

        # load client's public key from X9.62 uncompressed point
        client_pub = ec.EllipticCurvePublicKey.from_encoded_point(ec.SECP256R1(), client_pub_bytes)

        # derive shared secret and session key
        shared = server_priv.exchange(ec.ECDH(), client_pub)
        hkdf = HKDF(algorithm=hashes.SHA256(), length=32, salt=None, info=b"toy-ssh-session")
        session_key = hkdf.derive(shared)
        print("\nDerived session key (hex) (logged on server):", binascii.hexlify(session_key).decode())

        # decrypt
        aesgcm = AESGCM(session_key)
        plaintext = aesgcm.decrypt(nonce, ciphertext, associated_data=None)
        print("\nDecrypted plaintext (server):", plaintext.decode())

print("Server done.")
time.sleep(1)
