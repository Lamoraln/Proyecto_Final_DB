"""Genera claves locales y configura una contraseña web por usuario."""
import argparse
import getpass
import os
from pathlib import Path

import psycopg
from argon2 import PasswordHasher
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PrivateKey
from dotenv import dotenv_values

RAIZ = Path(__file__).resolve().parent


def claves():
    carpeta = RAIZ / ".claves"
    carpeta.mkdir(mode=0o700, exist_ok=True)
    privada = carpeta / "privada.pem"
    publica = carpeta / "publica.pem"
    # Reutilizamos la clave privada para conservar la misma firma entre arranques.
    if privada.exists():
        clave = serialization.load_pem_private_key(privada.read_bytes(), password=None)
    else:
        clave = Ed25519PrivateKey.generate()
        fd = os.open(privada, os.O_CREAT | os.O_EXCL | os.O_WRONLY, 0o600)
        with os.fdopen(fd, "wb") as archivo:
            archivo.write(clave.private_bytes(
                serialization.Encoding.PEM, serialization.PrivateFormat.PKCS8,
                serialization.NoEncryption(),
            ))
    # Las otras API usan esta clave para verificar la firma de Identidad.
    publica.write_bytes(clave.public_key().public_bytes(
        serialization.Encoding.PEM, serialization.PublicFormat.SubjectPublicKeyInfo,
    ))
    print("Claves disponibles en .claves.")


def contrasena(usuario):
    config = dotenv_values(RAIZ / "services/identidad-service/.env")
    admin = input("Usuario PostgreSQL administrador de Identidad: ").strip()
    clave_db = getpass.getpass("Contraseña PostgreSQL: ")
    nueva = getpass.getpass("Nueva contraseña web (mínimo 12 caracteres): ")
    if len(nueva) < 12 or len(nueva) > 256:
        raise SystemExit("Usa entre 12 y 256 caracteres.")
    if nueva != getpass.getpass("Confirma la contraseña web: "):
        raise SystemExit("Las contraseñas no coinciden.")
    # Usamos el acceso de PostgreSQL para guardar el hash de la nueva clave web.
    with psycopg.connect(
        host=config["DB_HOST"], port=config.get("DB_PORT") or "5432",
        dbname=config.get("DB_NAME") or "db_identidad",
        sslmode=config.get("DB_SSLMODE") or "require", user=admin, password=clave_db,
        connect_timeout=5,
    ) as db:
        cursor = db.execute(
            "UPDATE identidad.usuarios SET password_hash=%s WHERE nombre_usuario=%s",
            (PasswordHasher().hash(nueva), usuario),
        )
        if cursor.rowcount != 1:
            raise SystemExit("El usuario web indicado no existe.")
    print(f"Contraseña web actualizada para {usuario}.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    comandos = parser.add_subparsers(dest="comando", required=True)
    comandos.add_parser("claves")
    editar = comandos.add_parser("contrasena")
    editar.add_argument("usuario")
    args = parser.parse_args()
    if args.comando == "claves":
        claves()
    else:
        contrasena(args.usuario)
