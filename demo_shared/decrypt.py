#!/usr/bin/env python3
import sys, binascii
from cryptography.hazmat.primitives.serialization import load_pem_private_key
from cryptography.hazmat.primitives.asymmetric import ec
from cryptography.hazmat.primitives.kdf.hkdf import HKDF
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.ciphers.aead import AESGCM

if len(sys.argv) != 4:
    print("Usage: python decrypt.py server_priv.pem harvested_client_pub.hex harvested_cipher.hex")
    sys.exit(1)

server_priv_pem = sys.argv[1]
client_pub_hex = open(sys.argv[2]).read().strip()
cipher_hex = open(sys.argv[3]).read().strip()

# cipher file expected to contain two lines: nonce_hex then ciphertext_hex
nonce_hex, ciphertext_hex = cipher_hex.splitlines()

with open(server_priv_pem, "rb") as f:
    server_priv = load_pem_private_key(f.read(), password=None)

client_pub_bytes = binascii.unhexlify(client_pub_hex)
client_pub = ec.EllipticCurvePublicKey.from_encoded_point(ec.SECP256R1(), client_pub_bytes)

shared = server_priv.exchange(ec.ECDH(), client_pub)
hkdf = HKDF(algorithm=hashes.SHA256(), length=32, salt=None, info=b"toy-ssh-session")
session_key = hkdf.derive(shared)
print("Derived session key (attacker using server_priv.pem):", binascii.hexlify(session_key).decode())

nonce = binascii.unhexlify(nonce_hex)
ciphertext = binascii.unhexlify(ciphertext_hex)
pt = AESGCM(session_key).decrypt(nonce, ciphertext, associated_data=None)
print("Decrypted plaintext:", pt.decode())
