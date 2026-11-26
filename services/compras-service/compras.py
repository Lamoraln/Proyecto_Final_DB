from fastapi import Depends

from comun import BaseDatos, GLOBAL, almacenes_autorizados, permitir, servicio

db = BaseDatos(__file__, "db_compras")
app = servicio("Compras y Abastecimiento", db)
lectura = permitir(*GLOBAL, "RESP_COMPRAS")


@app.get("/api/compras/ordenes")
def ordenes(cuenta=Depends(lectura)):
    almacenes = almacenes_autorizados(cuenta, db.config)
    return db.consultar("""
        SELECT o.id_orden_compra, o.id_proveedor, o.id_almacen_destino,
               o.fecha_estimada::date, o.estado,
               COALESCE(d.lineas, '[]') AS lineas, COALESCE(r.recepciones, '[]') AS recepciones
        FROM compras.ordenes_compra o
        LEFT JOIN LATERAL (
            SELECT jsonb_agg(jsonb_build_object(
                'id_producto', d.id_producto, 'solicitada', d.cantidad_solicitada
            ) ORDER BY d.id_producto) AS lineas
            FROM compras.detalle_orden_compra d WHERE d.id_orden_compra=o.id_orden_compra
        ) d ON true
        LEFT JOIN LATERAL (
            SELECT jsonb_agg(jsonb_build_object(
                'codigo', r.id_recepcion, 'lineas', COALESCE(d.lineas, '[]')
            ) ORDER BY r.id_recepcion) AS recepciones
            FROM compras.recepciones_compra r
            LEFT JOIN LATERAL (
                SELECT jsonb_agg(jsonb_build_object(
                    'id_producto', d.id_producto, 'cantidad', d.cantidad_recibida
                ) ORDER BY d.id_producto) AS lineas
                FROM compras.detalle_recepcion d WHERE d.id_recepcion=r.id_recepcion
            ) d ON true
            WHERE r.id_orden_compra=o.id_orden_compra
        ) r ON true
        WHERE %s::int[] IS NULL OR o.id_almacen_destino = ANY(%s)
        ORDER BY o.fecha_orden DESC, o.id_orden_compra DESC
    """, (almacenes, almacenes))
