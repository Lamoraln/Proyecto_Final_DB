"""Ejecuta toda la aplicación o un servicio con procesos independientes."""
import argparse
import os
import subprocess
import sys
import time
from pathlib import Path

RAIZ = Path(__file__).resolve().parent
SERVICIOS = {
    "web": ("", "pasarela", 8000),
    "catalogo": ("catalogo-service", "catalogo", 8001),
    "inventarios": ("inventario-service", "inventario", 8002),
    "identidad": ("identidad-service", "identidad", 8003),
    "compras": ("compras-service", "compras", 8004),
    "ventas": ("ventas-service", "ventas", 8005),
    "reportes": ("reportes-service", "reportes", 8006),
}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("servicio", choices=("todos", *SERVICIOS), nargs="?", default="todos")
    opcion = parser.parse_args().servicio
    grupo = SERVICIOS.items() if opcion == "todos" else [(opcion, SERVICIOS[opcion])]
    # Así cada API encuentra comun.py aunque se ejecute desde su propia carpeta.
    env = dict(os.environ)
    env["PYTHONPATH"] = os.pathsep.join(filter(None, [str(RAIZ / "services"), env.get("PYTHONPATH")]))
    procesos = {}
    try:
        for nombre, (carpeta, modulo, puerto) in grupo:
            procesos[nombre] = subprocess.Popen(
                [sys.executable, "-m", "uvicorn", f"{modulo}:app", "--host", "127.0.0.1",
                 "--port", str(puerto), "--app-dir", str(RAIZ / "services" / carpeta)],
                cwd=RAIZ, env=env,
            )
        # Si un servicio se cae, los demás siguen corriendo.
        while procesos:
            for nombre, proceso in list(procesos.items()):
                codigo = proceso.poll()
                if codigo is not None:
                    print(f"{nombre} terminó con código {codigo}.", flush=True)
                    del procesos[nombre]
                    if opcion != "todos":
                        return codigo
            time.sleep(0.3)
    # Con Ctrl+C salimos del ciclo y cerramos los procesos que quedan.
    except KeyboardInterrupt:
        pass
    finally:
        for proceso in procesos.values():
            if proceso.poll() is None:
                proceso.terminate()
        for proceso in procesos.values():
            try:
                proceso.wait(timeout=5)
            except subprocess.TimeoutExpired:
                proceso.kill()
                proceso.wait()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
