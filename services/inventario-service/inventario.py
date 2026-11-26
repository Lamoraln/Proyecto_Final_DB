from fastapi import Depends, HTTPException, Query
from pydantic import BaseModel, Field

from comun import BaseDatos, GLOBAL, almacenes_autorizados, permitir, servicio

db = BaseDatos(__file__, "db_inventario")
app = servicio("Inventarios y Transferencias", db)
lectura = permitir(*GLOBAL, "RESP_INVENTARIO")
escritura = permitir("ADMINISTRADOR", "RESP_INVENTARIO")


@app.get("/api/inventarios")
def listar_inventario(sede_id: int = Query(gt=0), cuenta=Depends(lectura)):
    # La API valida la sede aunque alguien cambie el ID en la URL.
    filas = db.consultar("""
        SELECT id_sede, id_almacen, id_producto,
               existencia_actual AS existencia, stock_minimo AS minimo
        FROM inventarios.inventarios WHERE id_sede = %s
        ORDER BY id_producto, id_almacen
    """, (cuenta.alcance(sede_id),))
    editable = db.config.get("INVENTARIO_ESCRITURA") == "1" and cuenta.rol in ("ADMINISTRADOR", "RESP_INVENTARIO")
    return [{**fila, "editable": editable} for fila in filas]


class Minimo(BaseModel):
    minimo: int = Field(ge=0, le=2147483647)


@app.patch("/api/inventarios/{sede}/{almacen}/{producto}/minimo")
def actualizar_minimo(sede: int, almacen: int, producto: int, datos: Minimo,
                      cuenta=Depends(escritura)):
    # La edición del mínimo solo se habilita con la opción del servicio.
    if db.config.get("INVENTARIO_ESCRITURA") != "1":
        raise HTTPException(403, "La escritura de inventario está deshabilitada.")
    rows = db.consultar("""
        UPDATE inventarios.inventarios SET stock_minimo = %s, fecha_actualizacion = now()
        WHERE id_sede = %s AND id_almacen = %s AND id_producto = %s
        RETURNING stock_minimo AS minimo
    """, (datos.minimo, cuenta.alcance(sede), almacen, producto))
    if not rows:
        raise HTTPException(404, "No existe el registro de inventario solicitado.")
    return rows[0]


@app.get("/api/inventarios/transferencias")
def transferencias(cuenta=Depends(lectura)):
    # El traslado se puede consultar si uno de sus extremos queda dentro del alcance.
    almacenes = almacenes_autorizados(cuenta, db.config)
    return db.consultar("""
        SELECT t.id_transferencia, t.id_almacen_origen, t.id_almacen_destino,
               t.fecha_despacho::date, t.fecha_recepcion::date, t.estado,
               COALESCE(jsonb_agg(jsonb_build_object(
                   'id_producto', d.id_producto, 'enviada', d.cantidad_enviada,
                   'recibida', d.cantidad_recibida
               ) ORDER BY d.id_producto) FILTER (WHERE d.id_producto IS NOT NULL), '[]') AS productos
        FROM inventarios.transferencias t
        LEFT JOIN inventarios.detalle_transferencia d USING (id_transferencia)
        WHERE %s::int[] IS NULL OR t.id_almacen_origen = ANY(%s) OR t.id_almacen_destino = ANY(%s)
        GROUP BY t.id_transferencia ORDER BY t.fecha_solicitud DESC, t.id_transferencia DESC
    """, (almacenes, almacenes, almacenes))
