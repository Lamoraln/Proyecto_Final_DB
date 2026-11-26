-- 01. Inventario y valorización al precio de lista.
SELECT i.*, c.nombre AS categoria, p.precio_lista,
       i.existencia_actual * p.precio_lista AS valor_estimado
FROM reportes.vista_inventario_por_sede i
JOIN reportes.src_catalogo_productos p USING (id_producto)
JOIN reportes.src_catalogo_categorias c USING (id_categoria)
ORDER BY i.id_sede, i.id_almacen, i.sku;

-- 02. Alertas, incluidos los agotados con mínimo cero.
SELECT * FROM reportes.vista_alertas_reabastecimiento
ORDER BY faltante_minimo DESC, id_sede, id_almacen, id_producto;

-- 03. Productos activos sin registro en cada sede.
SELECT * FROM reportes.vista_productos_sin_inventario ORDER BY id_sede, sku;

-- 04. Cinco productos por sede y mes, con desempate estable.
WITH volumen AS (
    SELECT v.id_sede, date_trunc('month', v.fecha_pedido) AS mes,
           d.id_producto, sum(d.cantidad) AS unidades
    FROM reportes.src_ventas_pedidos_venta v
    JOIN reportes.src_ventas_detalle_pedido d USING (id_sede, id_pedido)
    WHERE v.estado IN ('CONFIRMADO', 'COMPLETADO')
    GROUP BY 1, 2, 3
), ranking AS (
    SELECT *, row_number() OVER (
        PARTITION BY id_sede, mes ORDER BY unidades DESC, id_producto
    ) AS puesto
    FROM volumen
)
SELECT r.*, p.sku, p.nombre FROM ranking r
JOIN reportes.src_catalogo_productos p USING (id_producto)
WHERE puesto <= 5 ORDER BY id_sede, mes, puesto;

-- 05. Ventas y variación respecto del mes calendario anterior.
WITH ventas AS (
    SELECT * FROM reportes.vista_ventas_mensuales_por_sede
), meses AS (
    SELECT generate_series(min(mes), max(mes), interval '1 month') AS mes FROM ventas
), serie AS (
    SELECT s.id_sede, s.nombre_sede, m.mes, coalesce(v.total_ventas, 0) AS total_ventas
    FROM reportes.vw_sedes s CROSS JOIN meses m
    LEFT JOIN ventas v USING (id_sede, mes)
), comparacion AS (
    SELECT *, lag(total_ventas) OVER (PARTITION BY id_sede ORDER BY mes) AS mes_anterior
    FROM serie
)
SELECT *, total_ventas - mes_anterior AS variacion,
       round(100 * (total_ventas - mes_anterior) / nullif(mes_anterior, 0), 2) AS variacion_pct
FROM comparacion ORDER BY id_sede, mes;

-- 06. Clientes con ventas efectivas en dos o más sedes.
SELECT c.id_cliente, c.nombre_completo,
       array_agg(DISTINCT s.nombre_sede ORDER BY s.nombre_sede) AS sedes,
       sum(v.total_registrado) AS total_comprado
FROM reportes.src_ventas_pedidos_venta v
JOIN reportes.src_catalogo_clientes c USING (id_cliente)
JOIN reportes.vw_sedes s USING (id_sede)
WHERE v.estado IN ('CONFIRMADO', 'COMPLETADO')
GROUP BY c.id_cliente, c.nombre_completo
HAVING count(DISTINCT v.id_sede) >= 2
ORDER BY total_comprado DESC, c.id_cliente;

-- 07. Saldos pendientes con el cliente del pedido.
SELECT s.*, c.nombre_completo AS cliente
FROM reportes.vista_saldos_pendientes s
JOIN reportes.src_ventas_pedidos_venta v USING (id_sede, id_pedido)
JOIN reportes.src_catalogo_clientes c USING (id_cliente)
ORDER BY saldo_pendiente DESC, id_sede, id_pedido;

-- 08. Pedidos con tres productos distintos o más.
SELECT v.id_sede, v.id_pedido, v.total_registrado,
       count(DISTINCT d.id_producto) AS productos, sum(d.cantidad) AS unidades,
       sum(d.cantidad * d.precio_unitario) AS importe_detalle
FROM reportes.src_ventas_pedidos_venta v
JOIN reportes.src_ventas_detalle_pedido d USING (id_sede, id_pedido)
GROUP BY v.id_sede, v.id_pedido, v.total_registrado
HAVING count(DISTINCT d.id_producto) >= 3
ORDER BY v.id_sede, v.id_pedido;

-- 09. Fecha de corte reproducible para los datos de prueba y umbral de 30 días.
SELECT p.*, date '2026-10-31' - p.fecha_pedido::date AS dias_pendiente
FROM reportes.vista_pedidos_pendientes p
WHERE p.fecha_pedido::date < date '2026-10-31' - 30
ORDER BY dias_pendiente DESC, id_sede, id_pedido;

-- 10. Demanda que supera el registro del mismo almacén; ausencia equivale a cero.
SELECT v.id_sede, v.id_almacen, v.id_pedido, p.sku, d.cantidad,
       coalesce(i.existencia_actual, 0) AS existencia
FROM reportes.src_ventas_pedidos_venta v
JOIN reportes.src_ventas_detalle_pedido d USING (id_sede, id_pedido)
JOIN reportes.src_catalogo_productos p USING (id_producto)
LEFT JOIN reportes.src_inventarios_inventarios i
    USING (id_sede, id_almacen, id_producto)
WHERE v.estado = 'PENDIENTE' AND d.cantidad > coalesce(i.existencia_actual, 0)
ORDER BY v.id_sede, v.id_pedido, p.sku;

-- 11. Cumplimiento por proveedor, a partir de la fecha de recepción total.
WITH recepcion_total AS (
    SELECT id_orden_compra, max(fecha_recepcion) FILTER (WHERE estado = 'TOTAL') AS fecha
    FROM reportes.src_compras_recepciones_compra GROUP BY id_orden_compra
)
SELECT p.id_proveedor, p.razon_social, count(o.id_orden_compra) AS ordenes,
       count(r.fecha) FILTER (WHERE r.fecha <= o.fecha_estimada) AS a_tiempo,
       round(avg(greatest(r.fecha::date - o.fecha_estimada::date, 0))
             FILTER (WHERE r.fecha IS NOT NULL AND o.fecha_estimada IS NOT NULL), 2)
             AS dias_retraso_promedio
FROM reportes.src_catalogo_proveedores p
LEFT JOIN reportes.src_compras_ordenes_compra o USING (id_proveedor)
LEFT JOIN recepcion_total r USING (id_orden_compra)
GROUP BY p.id_proveedor, p.razon_social ORDER BY p.id_proveedor;

-- 12. Compras y recepciones parciales pendientes.
SELECT * FROM reportes.vista_compras_pendientes ORDER BY id_orden_compra, id_producto;

-- 13. Transferencias despachadas y sin recibir a la fecha de corte.
SELECT t.*, date '2026-10-31' - t.fecha_despacho::date AS dias_transcurridos
FROM reportes.vista_transferencias_en_transito t
WHERE t.fecha_despacho::date <= date '2026-10-31'
ORDER BY dias_transcurridos DESC, id_transferencia, id_producto;

-- 14. Diferencia positiva si se recibió de más; negativa si se recibió de menos.
SELECT t.id_transferencia, t.id_almacen_origen, t.id_almacen_destino,
       p.sku, d.cantidad_enviada, d.cantidad_recibida,
       d.cantidad_recibida - d.cantidad_enviada AS diferencia
FROM reportes.src_inventarios_transferencias t
JOIN reportes.src_inventarios_detalle_transferencia d USING (id_transferencia)
JOIN reportes.src_catalogo_productos p USING (id_producto)
WHERE d.cantidad_recibida <> d.cantidad_enviada
ORDER BY t.id_transferencia, p.sku;

-- 15. Pares de sedes para redistribución. Se agregan sus almacenes primero.
WITH saldo AS (
    SELECT id_sede, id_producto, sum(existencia_actual) - sum(stock_minimo) AS diferencia
    FROM reportes.src_inventarios_inventarios GROUP BY id_sede, id_producto
)
SELECT p.sku, a.id_sede AS origen, b.id_sede AS destino,
       least(a.diferencia, -b.diferencia) AS unidades_sugeridas
FROM saldo a JOIN saldo b USING (id_producto)
JOIN reportes.src_catalogo_productos p USING (id_producto)
WHERE a.diferencia > 0 AND b.diferencia < 0 AND a.id_sede <> b.id_sede
ORDER BY p.sku, origen, destino;

-- 16. Existencias positivas sin ventas confirmadas durante los últimos 90 días del corte.
SELECT i.id_sede, i.id_almacen, p.sku, p.nombre, i.existencia_actual
FROM reportes.src_inventarios_inventarios i
JOIN reportes.src_catalogo_productos p USING (id_producto)
WHERE i.existencia_actual > 0 AND NOT EXISTS (
    SELECT 1 FROM reportes.src_ventas_pedidos_venta v
    JOIN reportes.src_ventas_detalle_pedido d USING (id_sede, id_pedido)
    WHERE v.id_sede = i.id_sede AND v.id_almacen = i.id_almacen
      AND d.id_producto = i.id_producto AND v.estado IN ('CONFIRMADO', 'COMPLETADO')
      AND v.fecha_pedido >= date '2026-11-01' - 90 AND v.fecha_pedido < date '2026-11-01'
)
ORDER BY i.id_sede, p.sku, i.id_almacen;

-- 17. Tasas de devolución por producto y categoría para el periodo de prueba.
WITH vendidos AS (
    SELECT d.id_producto, sum(d.cantidad) AS unidades
    FROM reportes.src_ventas_detalle_pedido d
    JOIN reportes.src_ventas_pedidos_venta v USING (id_sede, id_pedido)
    WHERE v.estado IN ('CONFIRMADO', 'COMPLETADO')
      AND v.fecha_pedido >= date '2026-07-01' AND v.fecha_pedido < date '2026-11-01'
    GROUP BY d.id_producto
), devueltos AS (
    SELECT d.id_producto, sum(d.cantidad) AS unidades
    FROM reportes.src_ventas_detalle_devolucion d
    JOIN reportes.src_ventas_devoluciones r USING (id_devolucion, id_sede, id_pedido)
    JOIN reportes.src_ventas_pedidos_venta v USING (id_sede, id_pedido)
    WHERE r.estado = 'APROBADA' AND v.estado IN ('CONFIRMADO', 'COMPLETADO')
      AND v.fecha_pedido >= date '2026-07-01' AND v.fecha_pedido < date '2026-11-01'
      AND r.fecha_solicitud < date '2026-11-01'
    GROUP BY d.id_producto
)
SELECT p.sku, p.nombre, c.nombre AS categoria,
       v.unidades AS vendidas, coalesce(d.unidades, 0) AS devueltas,
       round(100.0 * coalesce(d.unidades, 0) / nullif(v.unidades, 0), 2) AS porcentaje
FROM vendidos v JOIN reportes.src_catalogo_productos p USING (id_producto)
JOIN reportes.src_catalogo_categorias c USING (id_categoria)
LEFT JOIN devueltos d USING (id_producto)
ORDER BY categoria, sku;

-- 18. Surtido disponible solo en la sede 1, o común con la sede 2.
WITH sede_1 AS (
    SELECT id_producto FROM reportes.src_inventarios_inventarios
    WHERE id_sede = 1 AND existencia_actual > 0
), sede_2 AS (
    SELECT id_producto FROM reportes.src_inventarios_inventarios
    WHERE id_sede = 2 AND existencia_actual > 0
), solo_1 AS (
    SELECT id_producto FROM sede_1 EXCEPT SELECT id_producto FROM sede_2
), comunes AS (
    SELECT id_producto FROM sede_1 INTERSECT SELECT id_producto FROM sede_2
), surtido AS (
    SELECT id_producto, 'Solo sede 1' AS grupo FROM solo_1
    UNION ALL
    SELECT id_producto, 'Ambas sedes' FROM comunes
)
SELECT s.grupo, p.sku, p.nombre FROM surtido s
JOIN reportes.src_catalogo_productos p USING (id_producto)
ORDER BY grupo, sku;

-- 19. Clasificación por vendedor y sede, con empates.
WITH ventas AS (
    SELECT id_sede, id_empleado, sum(total_registrado) AS vendido
    FROM reportes.src_ventas_pedidos_venta
    WHERE estado IN ('CONFIRMADO', 'COMPLETADO')
    GROUP BY id_sede, id_empleado
)
SELECT v.*, e.nombre_completo,
       rank() OVER (PARTITION BY v.id_sede ORDER BY vendido DESC) AS puesto
FROM ventas v JOIN reportes.src_identidad_empleados e USING (id_empleado)
ORDER BY v.id_sede, puesto, v.id_empleado;

-- 20. Consolidado, con cada flujo agregado por sede antes de cruzarlo.
SELECT * FROM reportes.vista_reporte_corporativo ORDER BY id_sede;
