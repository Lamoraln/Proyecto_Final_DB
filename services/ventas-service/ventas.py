from fastapi import Depends, Query

from comun import BaseDatos, GLOBAL, permitir, servicio

db = BaseDatos(__file__, "db_ventas")
app = servicio("Ventas y Pagos", db)
lectura = permitir(*GLOBAL, "VENDEDOR")


@app.get("/api/ventas/pedidos")
def pedidos(sede_id: int | None = Query(default=None, gt=0), cuenta=Depends(lectura)):
    sede = cuenta.alcance(sede_id)
    return db.consultar("""
        SELECT v.id_sede, v.id_pedido, v.id_cliente, v.fecha_pedido::date, v.estado,
               v.total_registrado, COALESCE(d.lineas, '[]') AS lineas,
               COALESCE(p.pagos, '[]') AS pagos
        FROM ventas.pedidos_venta v
        LEFT JOIN LATERAL (
            SELECT jsonb_agg(jsonb_build_object(
                'id_producto', d.id_producto, 'cantidad', d.cantidad, 'precioUnitario', d.precio_unitario
            ) ORDER BY d.id_producto) AS lineas
            FROM ventas.detalle_pedido d WHERE (d.id_sede,d.id_pedido)=(v.id_sede,v.id_pedido)
        ) d ON true
        LEFT JOIN LATERAL (
            SELECT jsonb_agg(jsonb_build_object(
                'referencia', p.referencia_pago, 'fecha', p.fecha_pago::date,
                'medio', p.medio_pago, 'valor', p.valor, 'estado', p.estado
            ) ORDER BY p.id_pago) AS pagos
            FROM ventas.pagos p WHERE (p.id_sede,p.id_pedido)=(v.id_sede,v.id_pedido)
        ) p ON true
        WHERE %s::int IS NULL OR v.id_sede=%s
        ORDER BY v.fecha_pedido DESC, v.id_sede, v.id_pedido
    """, (sede, sede))


@app.get("/api/ventas/devoluciones")
def devoluciones(cuenta=Depends(permitir(*GLOBAL))):
    return db.consultar("""
        SELECT r.id_devolucion, r.id_sede, r.id_pedido, r.estado, r.motivo,
               d.id_producto, d.cantidad, d.condicion_producto
        FROM ventas.devoluciones r JOIN ventas.detalle_devolucion d
          USING (id_devolucion, id_sede, id_pedido)
        ORDER BY r.fecha_solicitud DESC, r.id_devolucion, d.id_producto
    """)
