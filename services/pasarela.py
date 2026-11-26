import re
from pathlib import Path

import httpx
from fastapi import FastAPI, HTTPException, Request, Response
from fastapi.staticfiles import StaticFiles

app = FastAPI(title="DistribuRed")
# La web entra por el puerto 8000 y la pasarela reparte las llamadas.
PUERTOS = {"catalogo": 8001, "inventarios": 8002, "identidad": 8003,
           "compras": 8004, "ventas": 8005, "reportes": 8006}


@app.api_route("/api/{servicio}", methods=["GET"])
@app.api_route("/api/{servicio}/{recurso:path}", methods=["GET", "POST", "PATCH"])
async def api(servicio: str, request: Request, recurso: str = ""):
    puerto = PUERTOS.get(servicio)
    if puerto is None or not re.fullmatch(r"[a-zA-Z0-9_/-]*", recurso):
        raise HTTPException(404, "Servicio desconocido.")
    ruta = f"/api/{servicio}" + (f"/{recurso}" if recurso else "")
    # Pasamos el token y el tipo de contenido al servicio que recibe la solicitud.
    headers = {k: request.headers[k] for k in ("authorization", "content-type") if k in request.headers}
    try:
        async with httpx.AsyncClient(timeout=15, trust_env=False) as cliente:
            respuesta = await cliente.request(
                request.method, f"http://127.0.0.1:{puerto}{ruta}",
                params=request.query_params, content=await request.body(), headers=headers,
            )
    # Si una API está apagada, solo falla la llamada a esa API.
    except httpx.RequestError as error:
        raise HTTPException(503, f"El servicio {servicio} no está disponible.") from error
    return Response(
        respuesta.content, status_code=respuesta.status_code,
        headers={k: respuesta.headers[k] for k in ("content-type", "www-authenticate")
                 if k in respuesta.headers} | {"Cache-Control": "no-store"},
    )


app.mount("/", StaticFiles(directory=Path(__file__).resolve().parents[1] / "frontend", html=True))
