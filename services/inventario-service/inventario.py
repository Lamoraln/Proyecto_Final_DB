import logging
import os
from pathlib import Path

import psycopg
from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from psycopg.rows import dict_row

load_dotenv(Path(__file__).resolve().with_name(".env"))
logger = logging.getLogger(__name__)

app = FastAPI(title="DistribuRed - Inventarios")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://127.0.0.1:8001"],
    allow_methods=["GET"],
)

SQL_INVENTARIO = """
    SELECT id_sede, id_almacen, id_producto,
           existencia_actual AS existencia,
           stock_minimo AS minimo
    FROM inventarios.inventarios
    WHERE id_sede = %s
    ORDER BY id_producto, id_almacen
"""


@app.get("/api/inventarios")
def listar_inventario(sede_id: int = Query(gt=0)):
    try:
        with psycopg.connect(
            host=os.environ["DB_HOST"],
            port=os.getenv("DB_PORT", "5432"),
            dbname=os.environ["DB_NAME"],
            user=os.environ["DB_USER"],
            password=os.environ["DB_PASSWORD"],
            sslmode=os.getenv("DB_SSLMODE", "require"),
            connect_timeout=5,
            row_factory=dict_row,
        ) as conexion:
            return conexion.execute(SQL_INVENTARIO, (sede_id,)).fetchall()
    except KeyError as error:
        logger.error("Falta una variable de Inventarios: %s", error)
        raise HTTPException(500, "Configuración de Inventarios incompleta.") from error
    except psycopg.OperationalError as error:
        logger.error("Error de conexión a Inventarios. SQLSTATE=%s", error.sqlstate)
        raise HTTPException(503, "La base de Inventarios no está disponible.") from error
    except psycopg.Error as error:
        logger.error("Falló la consulta de Inventarios. SQLSTATE=%s", error.sqlstate)
        raise HTTPException(500, "No se pudo consultar el inventario.") from error