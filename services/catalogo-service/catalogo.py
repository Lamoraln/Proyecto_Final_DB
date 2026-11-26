import logging
import os
from pathlib import Path

import psycopg
from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException
from fastapi.staticfiles import StaticFiles
from psycopg.rows import dict_row

CARPETA_SERVICIO = Path(__file__).resolve().parent
CARPETA_FRONTEND = CARPETA_SERVICIO.parents[1] / "frontend"

load_dotenv(CARPETA_SERVICIO / ".env")
logger = logging.getLogger(__name__)

app = FastAPI(title="DistribuRed - Catálogo y Terceros")


def consultar(sql: str) -> list[dict]:
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
            return conexion.execute(sql).fetchall()
    except KeyError as error:
        logger.error("Falta una variable de configuración: %s", error)
        raise HTTPException(500, "Configuración de Catálogo incompleta.") from error
    except psycopg.OperationalError as error:
        logger.error("No se pudo conectar a Catálogo. SQLSTATE=%s", error.sqlstate)
        raise HTTPException(503, "La base de Catálogo no está disponible.") from error
    except psycopg.Error as error:
        logger.error("Falló la consulta de Catálogo. SQLSTATE=%s", error.sqlstate)
        raise HTTPException(500, "No se pudo ejecutar la consulta de Catálogo.") from error


@app.get("/api/catalogo/conexion")
def verificar_conexion():
    return consultar("SELECT current_database() AS base")[0]


@app.get("/api/catalogo/sedes")
def listar_sedes():
    return consultar("""
        SELECT id_sede, codigo_sede, nombre, ciudad, tipo_sede, estado
        FROM catalogo.sedes
        ORDER BY nombre, id_sede
    """)


@app.get("/api/catalogo/almacenes")
def listar_almacenes():
    return consultar("""
        SELECT a.id_almacen, a.codigo_almacen, a.nombre, a.id_sede,
               s.nombre AS sede, a.tipo_almacen, a.estado
        FROM catalogo.almacenes AS a
        JOIN catalogo.sedes AS s ON s.id_sede = a.id_sede
        ORDER BY s.nombre, a.nombre, a.id_almacen
    """)


@app.get("/api/catalogo/productos")
def listar_productos():
    return consultar("""
        SELECT p.id_producto, p.sku, p.nombre, c.nombre AS categoria, p.estado
        FROM catalogo.productos AS p
        LEFT JOIN catalogo.categorias AS c ON c.id_categoria = p.id_categoria
        ORDER BY p.nombre, p.sku
    """)


@app.get("/api/catalogo/categorias")
def listar_categorias():
    return consultar("""
        SELECT c.id_categoria, c.nombre, COUNT(p.id_producto) AS referencias
        FROM catalogo.categorias AS c
        LEFT JOIN catalogo.productos AS p ON p.id_categoria = c.id_categoria
        GROUP BY c.id_categoria, c.nombre
        ORDER BY c.nombre, c.id_categoria
    """)


@app.get("/api/catalogo/proveedores")
def listar_proveedores():
    return consultar("""
        SELECT id_proveedor, razon_social, ciudad, estado
        FROM catalogo.proveedores
        ORDER BY razon_social, id_proveedor
    """)


@app.get("/api/catalogo/clientes")
def listar_clientes():
    return consultar("""
        SELECT id_cliente, nombre_completo, tipo_cliente, estado
        FROM catalogo.clientes
        ORDER BY nombre_completo, id_cliente
    """)


# Montar después de declarar las rutas de la API.
app.mount("/", StaticFiles(directory=CARPETA_FRONTEND, html=True), name="frontend")