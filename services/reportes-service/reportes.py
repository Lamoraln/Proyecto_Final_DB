from fastapi import Depends, HTTPException
from psycopg import sql

from comun import BaseDatos, GLOBAL, permitir, servicio

db = BaseDatos(__file__, "db_reportes")
app = servicio("Reportes Corporativos", db)
lectura = permitir(*GLOBAL)


@app.get("/api/reportes/consolidado")
def consolidado(_=Depends(lectura)):
    return db.consultar("SELECT * FROM reportes.vista_reporte_corporativo ORDER BY id_sede")


@app.get("/api/reportes/inventario")
def inventario(_=Depends(lectura)):
    return db.consultar("SELECT * FROM reportes.vista_inventario_por_sede ORDER BY id_sede, id_almacen, id_producto")


@app.get("/api/reportes/ausencias")
def ausencias(_=Depends(lectura)):
    return db.consultar("SELECT id_sede, count(*) AS ausentes FROM reportes.vista_productos_sin_inventario GROUP BY id_sede")


VISTAS = frozenset({
    "inventario_por_sede", "alertas_reabastecimiento", "productos_sin_inventario",
    "ventas_mensuales_por_sede", "pedidos_pendientes", "saldos_pendientes",
    "compras_pendientes", "transferencias_en_transito", "devoluciones_por_producto",
    "reporte_corporativo",
})


@app.get("/api/reportes/vistas/{nombre}")
def ver_vista(nombre: str, _=Depends(lectura)):
    if nombre not in VISTAS:
        raise HTTPException(404, "Vista de Reportes desconocida.")
    consulta = sql.SQL("SELECT * FROM {}.{} ORDER BY 1").format(
        sql.Identifier("reportes"), sql.Identifier("vista_" + nombre),
    )
    with db.conexion() as conexion:
        cursor = conexion.execute(consulta)
        return {"columnas": [c.name for c in cursor.description], "filas": cursor.fetchall()}
