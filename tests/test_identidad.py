import jwt
import pytest
from argon2 import PasswordHasher
from fastapi.testclient import TestClient

import identidad

from conftest import AUDIENCIA, EMISOR

CLAVE = "clave-correcta-123"
HASH = PasswordHasher().hash(CLAVE)


def usuario(**cambios):
    fila = {
        "id_usuario": 9, "password_hash": HASH, "rol": "VENDEDOR", "estado": "ACTIVO",
        "id_sede": 2, "nombre_completo": "Ana Pérez", "estado_empleado": "ACTIVO",
    }
    return {**fila, **cambios}


@pytest.fixture
def cliente():
    return TestClient(identidad.app)


@pytest.fixture
def base(monkeypatch):
    """Permite fijar las filas que devuelve la consulta de login."""
    filas = {"login": []}

    def consultar(consulta, parametros=None):
        return filas.get("login") if "identidad.usuarios u" in consulta and "JOIN" in consulta else []

    monkeypatch.setattr(identidad.db, "consultar", consultar)
    return filas


def login(cliente, usuario_="ana", contrasena=CLAVE):
    return cliente.post("/api/identidad/login", json={"usuario": usuario_, "contrasena": contrasena})


def test_login_correcto_emite_token_verificable(cliente, base, claves):
    base["login"] = [usuario()]
    respuesta = login(cliente)

    assert respuesta.status_code == 200
    assert respuesta.headers["Cache-Control"] == "no-store"
    cuerpo = respuesta.json()
    datos = jwt.decode(cuerpo["token"], claves["publica"].read_bytes(), algorithms=["EdDSA"],
                       issuer=EMISOR, audience=AUDIENCIA)
    assert (datos["sub"], datos["rol"], datos["sede"]) == ("9", "VENDEDOR", 2)
    assert cuerpo["perfil"] == {"id": 9, "nombre": "Ana Pérez", "rol": "VENDEDOR", "sedes": [2]}


def test_rol_global_no_tiene_sedes_fijas(cliente, base, claves):
    base["login"] = [usuario(rol="GERENCIA")]
    perfil = login(cliente).json()["perfil"]
    assert perfil["sedes"] is None


def test_contrasena_incorrecta_responde_401(cliente, base, claves):
    base["login"] = [usuario()]
    respuesta = login(cliente, contrasena="otra-clave")
    assert respuesta.status_code == 401


def test_usuario_inexistente_responde_igual_que_contrasena_incorrecta(cliente, base, claves):
    base["login"] = []
    inexistente = login(cliente)
    base["login"] = [usuario()]
    incorrecta = login(cliente, contrasena="otra-clave")
    assert inexistente.status_code == incorrecta.status_code == 401
    assert inexistente.json() == incorrecta.json()


@pytest.mark.parametrize("cambios", [
    {"estado": "INACTIVO"},
    {"estado_empleado": "RETIRADO"},
    {"rol": "SIN_ROL"},
])
def test_cuenta_o_empleado_inactivo_no_inicia_sesion(cliente, base, claves, cambios):
    base["login"] = [usuario(**cambios)]
    assert login(cliente).status_code == 401


def test_usuario_con_hash_corrupto_responde_401(cliente, base, claves):
    base["login"] = [usuario(password_hash="no-es-un-hash")]
    assert login(cliente).status_code == 401


def test_datos_de_login_fuera_de_limite_responde_422(cliente, base, claves):
    assert login(cliente, usuario_="").status_code == 422


def test_directorio_exige_token(cliente, base, claves):
    assert cliente.get("/api/identidad/directorio").status_code == 401


def test_directorio_rechaza_roles_que_no_son_administrador(cliente, base, claves, emitir_token):
    token = emitir_token(rol="GERENCIA", sede=1)
    respuesta = cliente.get("/api/identidad/directorio", headers={"Authorization": f"Bearer {token}"})
    assert respuesta.status_code == 403


def test_directorio_acepta_administrador(cliente, base, claves, emitir_token, monkeypatch):
    monkeypatch.setattr(identidad.db, "consultar", lambda consulta, parametros=None: [])
    token = emitir_token(rol="ADMINISTRADOR", sede=1)
    respuesta = cliente.get("/api/identidad/directorio", headers={"Authorization": f"Bearer {token}"})
    assert respuesta.status_code == 200
    assert set(respuesta.json()) == {"empleados", "usuarios", "auditoria"}
