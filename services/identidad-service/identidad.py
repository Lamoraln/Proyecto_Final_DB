import os
from datetime import datetime, timedelta, timezone
from pathlib import Path

import jwt
from argon2 import PasswordHasher
from argon2.exceptions import InvalidHashError, VerificationError
from fastapi import Depends, HTTPException, Response
from pydantic import BaseModel, Field

from comun import AUDIENCIA, EMISOR, GLOBAL, RAIZ, ROLES, BaseDatos, permitir, servicio

db = BaseDatos(__file__, "db_identidad")
app = servicio("Identidad y Accesos", db)
hasher = PasswordHasher()
hash_inexistente = hasher.hash("usuario-inexistente")
ACTIVOS = ("ACTIVO", "ACTIVA")
administrador = permitir("ADMINISTRADOR")


class Credenciales(BaseModel):
    usuario: str = Field(min_length=1, max_length=50)
    contrasena: str = Field(min_length=1, max_length=256)


@app.post("/api/identidad/login")
def login(datos: Credenciales, respuesta: Response):
    usuarios = db.consultar("""
        SELECT u.id_usuario, u.password_hash, u.rol, u.estado,
               e.id_sede, e.nombre_completo, e.estado AS estado_empleado
        FROM identidad.usuarios u
        JOIN identidad.empleados e USING (id_empleado)
        WHERE u.nombre_usuario = %s
    """, (datos.usuario.strip(),))
    usuario = usuarios[0] if usuarios else None
    try:
        valida = hasher.verify(usuario["password_hash"] if usuario else hash_inexistente, datos.contrasena)
    except (InvalidHashError, VerificationError):
        valida = False
    if not (
        valida and usuario and usuario["estado"] in ACTIVOS
        and usuario["estado_empleado"] in ACTIVOS and usuario["rol"] in ROLES
    ):
        raise HTTPException(401, "Usuario o contraseña incorrectos.")

    ahora = datetime.now(timezone.utc)
    vence = ahora + timedelta(minutes=30)
    try:
        privada = Path(os.getenv("JWT_PRIVATE_KEY_FILE", RAIZ / ".claves/privada.pem")).read_bytes()
    except OSError as error:
        raise HTTPException(503, "Falta la clave de firma de Identidad.") from error
    token = jwt.encode({
        "sub": str(usuario["id_usuario"]), "rol": usuario["rol"], "sede": usuario["id_sede"],
        "exp": vence, "iat": ahora, "iss": EMISOR, "aud": AUDIENCIA,
    }, privada, algorithm="EdDSA")
    respuesta.headers["Cache-Control"] = "no-store"
    return {"token": token, "expira": int(vence.timestamp()), "perfil": {
        "id": usuario["id_usuario"], "nombre": usuario["nombre_completo"], "rol": usuario["rol"],
        "sedes": None if usuario["rol"] in GLOBAL else [usuario["id_sede"]],
    }}


@app.get("/api/identidad/directorio")
def directorio(_=Depends(administrador)):
    return {
        "empleados": db.consultar("""
            SELECT id_empleado, id_sede, nombre_completo, cargo, estado
            FROM identidad.empleados ORDER BY id_empleado
        """),
        "usuarios": db.consultar("""
            SELECT u.nombre_usuario, e.nombre_completo, u.rol, u.estado
            FROM identidad.usuarios u JOIN identidad.empleados e USING (id_empleado)
            ORDER BY u.nombre_usuario
        """),
        "auditoria": db.consultar("""
            SELECT a.fecha_hora, u.nombre_usuario, a.accion, a.objeto_consultado, a.resultado
            FROM identidad.auditoria_accesos a JOIN identidad.usuarios u USING (id_usuario)
            ORDER BY a.fecha_hora DESC, a.id_auditoria DESC LIMIT 200
        """),
    }
