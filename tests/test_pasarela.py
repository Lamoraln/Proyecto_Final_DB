import httpx
import pytest
from fastapi.testclient import TestClient

import pasarela


class RespuestaFalsa:
    status_code = 200
    content = b'{"ok": true}'
    headers = {"content-type": "application/json", "www-authenticate": "Bearer", "x-interno": "no"}


@pytest.fixture
def enviados(monkeypatch):
    """Registra cada petición que la pasarela reenvía a un servicio."""
    llamadas = []

    class ClienteFalso:
        def __init__(self, *args, **kwargs):
            pass

        async def __aenter__(self):
            return self

        async def __aexit__(self, *args):
            return False

        async def request(self, metodo, url, **kwargs):
            llamadas.append({"metodo": metodo, "url": url, **kwargs})
            return RespuestaFalsa()

    monkeypatch.setattr(pasarela.httpx, "AsyncClient", ClienteFalso)
    return llamadas


@pytest.fixture
def cliente():
    return TestClient(pasarela.app)


def test_servicio_desconocido_responde_404(cliente):
    assert cliente.get("/api/desconocido").status_code == 404


@pytest.mark.parametrize("ruta", ["/api/catalogo/abc$def", "/api/catalogo/a%20b"])
def test_recurso_con_caracteres_no_permitidos_responde_404(cliente, enviados, ruta):
    assert cliente.get(ruta).status_code == 404
    assert enviados == []


def test_reenvia_al_puerto_del_servicio_con_cabeceras_permitidas(cliente, enviados):
    respuesta = cliente.get(
        "/api/inventarios/existencias",
        params={"sede": "2"},
        headers={"Authorization": "Bearer abc", "X-Ajena": "no"},
    )

    assert respuesta.status_code == 200
    assert respuesta.json() == {"ok": True}
    assert respuesta.headers["Cache-Control"] == "no-store"
    envio = enviados[0]
    assert envio["url"] == "http://127.0.0.1:8002/api/inventarios/existencias"
    assert envio["params"]["sede"] == "2"
    assert envio["headers"] == {"authorization": "Bearer abc"}


def test_servicio_caido_responde_503(cliente, monkeypatch):
    class ClienteCaido:
        def __init__(self, *args, **kwargs):
            pass

        async def __aenter__(self):
            return self

        async def __aexit__(self, *args):
            return False

        async def request(self, metodo, url, **kwargs):
            raise httpx.ConnectError("sin conexión")

    monkeypatch.setattr(pasarela.httpx, "AsyncClient", ClienteCaido)
    respuesta = cliente.get("/api/ventas/pedidos")
    assert respuesta.status_code == 503
    assert "ventas" in respuesta.json()["detail"]
