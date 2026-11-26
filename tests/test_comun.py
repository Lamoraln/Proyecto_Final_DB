import pytest
from fastapi import HTTPException
from fastapi.security import HTTPAuthorizationCredentials

from comun import Sesion, permitir, sesion

from conftest import AUDIENCIA, EMISOR


def credenciales(token):
    return HTTPAuthorizationCredentials(scheme="Bearer", credentials=token)


def test_sin_token_responde_401():
    with pytest.raises(HTTPException) as error:
        sesion(None)
    assert error.value.status_code == 401


def test_token_valido_construye_la_sesion(emitir_token):
    cuenta = sesion(credenciales(emitir_token(rol="VENDEDOR", sede=2, sub="15")))
    assert (cuenta.id, cuenta.rol, cuenta.sede) == (15, "VENDEDOR", 2)


@pytest.mark.parametrize("emisor, audiencia", [
    ("otro-emisor", AUDIENCIA),
    (EMISOR, "otra-audiencia"),
])
def test_token_de_otro_emisor_o_audiencia_responde_401(emitir_token, emisor, audiencia):
    token = emitir_token(emisor=emisor, audiencia=audiencia)
    with pytest.raises(HTTPException) as error:
        sesion(credenciales(token))
    assert error.value.status_code == 401


def test_token_expirado_responde_401(emitir_token):
    with pytest.raises(HTTPException) as error:
        sesion(credenciales(emitir_token(minutos=-5)))
    assert error.value.status_code == 401


def test_rol_desconocido_responde_401(emitir_token):
    with pytest.raises(HTTPException) as error:
        sesion(credenciales(emitir_token(rol="SUPERUSUARIO")))
    assert error.value.status_code == 401


@pytest.mark.parametrize("sede", [0, -1, "1"])
def test_sede_no_entera_positiva_responde_401(emitir_token, sede):
    with pytest.raises(HTTPException) as error:
        sesion(credenciales(emitir_token(sede=sede)))
    assert error.value.status_code == 401


def test_alcance_de_rol_global_no_se_restringe():
    cuenta = Sesion(1, "GERENCIA", 1, "t")
    assert cuenta.alcance() is None
    assert cuenta.alcance(sede=3) == 3


def test_vendedor_solo_consulta_su_sede():
    cuenta = Sesion(1, "VENDEDOR", 2, "t")
    assert cuenta.alcance() == 2
    assert cuenta.alcance(sede=2) == 2
    with pytest.raises(HTTPException) as error:
        cuenta.alcance(sede=3)
    assert error.value.status_code == 403


def test_permitir_rechaza_roles_fuera_de_la_lista():
    validar = permitir("ADMINISTRADOR")
    with pytest.raises(HTTPException) as error:
        validar(cuenta=Sesion(1, "VENDEDOR", 1, "t"))
    assert error.value.status_code == 403


def test_permitir_acepta_rol_incluido():
    cuenta = Sesion(1, "ADMINISTRADOR", 1, "t")
    assert permitir("ADMINISTRADOR")(cuenta=cuenta) is cuenta
