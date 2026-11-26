import logging
import os
from contextlib import contextmanager
from dataclasses import dataclass
from pathlib import Path

import httpx
import jwt
import psycopg
from dotenv import dotenv_values
from fastapi import Depends, FastAPI, HTTPException
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from psycopg.rows import dict_row

RAIZ = Path(__file__).resolve().parents[1]
EMISOR = "distribured-identidad"
AUDIENCIA = "distribured-servicios"
GLOBAL = ("ADMINISTRADOR", "GERENCIA", "AUDITOR")
ROLES = (*GLOBAL, "RESP_INVENTARIO", "RESP_COMPRAS", "VENDEDOR")
bearer = HTTPBearer(auto_error=False)
logger = logging.getLogger(__name__)


def configuracion(archivo):
    return {**dotenv_values(Path(archivo).with_name(".env")), **os.environ}


class BaseDatos:
    def __init__(self, archivo, base):
        self.config = configuracion(archivo)
        self.base = base

    @contextmanager
    def conexion(self):
        try:
            with psycopg.connect(
                host=self.config["DB_HOST"],
                port=self.config.get("DB_PORT", "5432"),
                dbname=self.config.get("DB_NAME") or self.base,
                user=self.config["DB_USER"],
                password=self.config["DB_PASSWORD"],
                sslmode=self.config.get("DB_SSLMODE", "require"),
                connect_timeout=5,
                options="-c statement_timeout=9000",
                row_factory=dict_row,
            ) as conexion:
                yield conexion
        except KeyError as error:
            logger.error("Falta %s en la configuración de %s", error, self.base)
            raise HTTPException(503, "Falta configurar la base del servicio.") from error
        except psycopg.OperationalError as error:
            logger.warning("Base %s no disponible (%s)", self.base, error.sqlstate)
            raise HTTPException(503, "La base del servicio no está disponible.") from error
        except psycopg.Error as error:
            logger.error("Consulta a %s falló (%s)", self.base, error.sqlstate)
            raise HTTPException(500, "La consulta a la base del servicio falló.") from error

    def consultar(self, consulta, parametros=None):
        with self.conexion() as conexion:
            return conexion.execute(consulta, parametros).fetchall()


def servicio(nombre, db):
    app = FastAPI(title=f"DistribuRed · {nombre}")

    @app.get("/salud")
    def salud():
        db.consultar("SELECT 1")
        return {"servicio": nombre, "base_disponible": True}

    return app


@dataclass(frozen=True)
class Sesion:
    id: int
    rol: str
    sede: int
    token: str

    def alcance(self, sede=None):
        if self.rol in GLOBAL:
            return sede
        if sede is not None and sede != self.sede:
            raise HTTPException(403, "La sede solicitada está fuera de tu alcance.")
        return self.sede


def clave_publica():
    return Path(os.getenv("JWT_PUBLIC_KEY_FILE", RAIZ / ".claves/publica.pem")).read_bytes()


def sesion(credenciales: HTTPAuthorizationCredentials | None = Depends(bearer)):
    if credenciales:
        try:
            datos = jwt.decode(
                credenciales.credentials, clave_publica(),
                algorithms=["EdDSA"], issuer=EMISOR, audience=AUDIENCIA,
                options={"require": ["exp", "iat", "sub", "rol", "sede"]},
            )
            if datos["rol"] in ROLES and type(datos["sede"]) is int and datos["sede"] > 0:
                return Sesion(int(datos["sub"]), datos["rol"], datos["sede"], credenciales.credentials)
        except (jwt.InvalidTokenError, ValueError, TypeError):
            pass
        except OSError as error:
            raise HTTPException(503, "Falta la clave pública de Identidad.") from error
    raise HTTPException(401, "Inicia sesión nuevamente.", headers={"WWW-Authenticate": "Bearer"})


def permitir(*roles):
    def validar(cuenta: Sesion = Depends(sesion)):
        if cuenta.rol not in roles:
            raise HTTPException(403, "Tu rol no tiene acceso a esta operación.")
        return cuenta
    return validar


def almacenes_autorizados(cuenta, config):
    sede = cuenta.alcance()
    if sede is None:
        return None
    try:
        origen = config.get("URL_CATALOGO") or "http://127.0.0.1:8001"
        respuesta = httpx.get(
            f"{origen.rstrip('/')}/api/catalogo/almacenes",
            headers={"Authorization": f"Bearer {cuenta.token}"},
            timeout=5, trust_env=False,
        )
        respuesta.raise_for_status()
        return [a["id_almacen"] for a in respuesta.json() if a["id_sede"] == sede]
    except (httpx.HTTPError, ValueError, KeyError, TypeError) as error:
        raise HTTPException(503, "Catálogo no pudo confirmar los almacenes autorizados.") from error
