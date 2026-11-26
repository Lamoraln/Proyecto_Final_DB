"""Configuración común de las pruebas de los servicios Python.

Las pruebas no necesitan PostgreSQL: las consultas a la base se sustituyen por
respuestas simuladas, y los tokens se firman con un par de claves temporal.
"""
import sys
from datetime import datetime, timedelta, timezone
from pathlib import Path

import jwt
import pytest
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric import ed25519

RAIZ = Path(__file__).resolve().parents[1]
for ruta in (RAIZ / "services", RAIZ / "services" / "identidad-service"):
    sys.path.insert(0, str(ruta))

EMISOR = "distribured-identidad"
AUDIENCIA = "distribured-servicios"


@pytest.fixture
def claves(tmp_path, monkeypatch):
    """Escribe un par Ed25519 en disco y apunta los servicios a esos archivos."""
    privada = ed25519.Ed25519PrivateKey.generate()
    ruta_privada = tmp_path / "privada.pem"
    ruta_publica = tmp_path / "publica.pem"
    ruta_privada.write_bytes(privada.private_bytes(
        serialization.Encoding.PEM, serialization.PrivateFormat.PKCS8,
        serialization.NoEncryption()))
    ruta_publica.write_bytes(privada.public_key().public_bytes(
        serialization.Encoding.PEM, serialization.PublicFormat.SubjectPublicKeyInfo))
    monkeypatch.setenv("JWT_PRIVATE_KEY_FILE", str(ruta_privada))
    monkeypatch.setenv("JWT_PUBLIC_KEY_FILE", str(ruta_publica))
    return {"privada": ruta_privada.read_bytes(), "publica": ruta_publica}


@pytest.fixture
def emitir_token(claves):
    """Crea tokens con la misma forma que emite Identidad."""
    def emitir(rol="VENDEDOR", sede=1, sub="7", minutos=30, emisor=EMISOR, audiencia=AUDIENCIA, **extra):
        ahora = datetime.now(timezone.utc)
        carga = {
            "sub": sub, "rol": rol, "sede": sede, "iat": ahora,
            "exp": ahora + timedelta(minutes=minutos), "iss": emisor, "aud": audiencia,
            **extra,
        }
        return jwt.encode(carga, claves["privada"], algorithm="EdDSA")
    return emitir
