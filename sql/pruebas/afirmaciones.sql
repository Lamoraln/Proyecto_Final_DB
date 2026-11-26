-- Aserciones para CI. Cada bloque repite la consulta de su archivo de pruebas y
-- falla si el resultado no es el esperado. Ejecutar con psql -v ON_ERROR_STOP=1
-- desde cualquier base de la instancia, después de cargar datos y casos.

-- Compras: integridad_compras.sql. Ninguna recepción supera lo solicitado ni
-- referencia una línea ajena a su orden.
\c db_compras
DO $afirmacion$
DECLARE res record;
BEGIN
    SELECT * INTO res FROM (
        SELECT (SELECT count(*) FROM compras.detalle_recepcion d JOIN compras.recepciones_compra r USING(id_recepcion) LEFT JOIN compras.detalle_orden_compra o USING(id_orden_compra,id_producto) WHERE o.id_producto IS NULL) lineas_ajenas, (SELECT count(*) FROM (SELECT r.id_orden_compra,d.id_producto,sum(d.cantidad_recibida) recibido FROM compras.detalle_recepcion d JOIN compras.recepciones_compra r USING(id_recepcion) GROUP BY 1,2) x JOIN compras.detalle_orden_compra o USING(id_orden_compra,id_producto) WHERE x.recibido>o.cantidad_solicitada) excedentes
    ) s;
    IF res.lineas_ajenas <> 0 OR res.excedentes <> 0 THEN
        RAISE EXCEPTION 'Recepciones inconsistentes: %', row_to_json(res);
    END IF;
END
$afirmacion$;

-- Ventas: integridad_ventas.sql. Las devoluciones, totales y pagos cuadran.
-- El único pago parcial esperado es el abono sintético de casos_ventas.sql.
\c db_ventas
DO $afirmacion$
DECLARE res record;
BEGIN
    SELECT * INTO res FROM (
        SELECT (SELECT count(*) FROM ventas.detalle_devolucion d JOIN ventas.devoluciones r USING(id_devolucion) WHERE (d.id_sede,d.id_pedido)<>(r.id_sede,r.id_pedido)) devolucion_otro_pedido,
        (SELECT count(*) FROM ventas.pedidos_venta v JOIN (SELECT id_sede,id_pedido,sum(cantidad*precio_unitario) total FROM ventas.detalle_pedido GROUP BY 1,2) d USING(id_sede,id_pedido) WHERE v.total_registrado<>d.total) totales_distintos,
        (SELECT count(*) FROM ventas.pedidos_venta v JOIN (SELECT id_sede,id_pedido,sum(valor) total FROM ventas.pagos WHERE estado='CONFIRMADO' GROUP BY 1,2) p USING(id_sede,id_pedido) WHERE p.total>v.total_registrado) sobrepagos,
        (SELECT count(*) FROM ventas.pedidos_venta v JOIN (SELECT id_sede,id_pedido,sum(valor) total FROM ventas.pagos WHERE estado='CONFIRMADO' GROUP BY 1,2) p USING(id_sede,id_pedido) WHERE p.total>0 AND p.total<v.total_registrado) pagos_parciales,
        (SELECT count(*) FROM (SELECT d.id_sede,d.id_pedido,d.id_producto,sum(d.cantidad) devolucion FROM ventas.detalle_devolucion d JOIN ventas.devoluciones r USING(id_devolucion) WHERE r.estado='APROBADA' GROUP BY 1,2,3) x JOIN ventas.detalle_pedido d USING(id_sede,id_pedido,id_producto) WHERE x.devolucion>d.cantidad) exceso_devolucion
    ) s;
    IF res.devolucion_otro_pedido <> 0 OR res.totales_distintos <> 0 OR res.sobrepagos <> 0
       OR res.exceso_devolucion <> 0 OR res.pagos_parciales <> 1 THEN
        RAISE EXCEPTION 'Integridad de ventas: %', row_to_json(res);
    END IF;
END
$afirmacion$;

-- Reportes: referencias_distribuidas.sql. Todos los controles de IDs compartidos dan cero.
\c db_reportes
DO $afirmacion$
DECLARE malos bigint;
BEGIN
    SELECT count(*) INTO malos FROM (
        SELECT 'Inventario' AS control, count(*) AS incumplimientos
        FROM reportes.src_inventarios_inventarios i
        LEFT JOIN reportes.src_catalogo_productos p USING (id_producto)
        LEFT JOIN reportes.src_catalogo_almacenes a USING (id_sede,id_almacen)
        WHERE p.id_producto IS NULL OR a.id_almacen IS NULL
        UNION ALL
        SELECT 'Pedidos', count(*)
        FROM reportes.src_ventas_pedidos_venta v
        LEFT JOIN reportes.src_catalogo_clientes c USING (id_cliente)
        LEFT JOIN reportes.src_catalogo_almacenes a USING (id_sede,id_almacen)
        LEFT JOIN reportes.src_identidad_empleados e USING (id_sede,id_empleado)
        WHERE c.id_cliente IS NULL OR a.id_almacen IS NULL OR e.id_empleado IS NULL
        UNION ALL
        SELECT 'Compras', count(*)
        FROM reportes.src_compras_ordenes_compra o
        LEFT JOIN reportes.src_catalogo_proveedores p USING (id_proveedor)
        LEFT JOIN reportes.src_catalogo_almacenes a ON a.id_almacen=o.id_almacen_destino
        LEFT JOIN reportes.src_identidad_empleados e USING (id_empleado)
        WHERE p.id_proveedor IS NULL OR a.id_almacen IS NULL OR e.id_empleado IS NULL
        UNION ALL
        SELECT 'Transferencias', count(*)
        FROM reportes.src_inventarios_transferencias t
        LEFT JOIN reportes.src_catalogo_almacenes a ON a.id_almacen=t.id_almacen_origen
        LEFT JOIN reportes.src_catalogo_almacenes b ON b.id_almacen=t.id_almacen_destino
        WHERE a.id_almacen IS NULL OR b.id_almacen IS NULL
    ) controles
    WHERE incumplimientos <> 0;
    IF malos <> 0 THEN
        RAISE EXCEPTION 'Referencias distribuidas: % control(es) con incumplimientos.', malos;
    END IF;
END
$afirmacion$;

-- Reportes: reportes.sql. El consolidado por sede coincide con las sumas de las fuentes.
DO $afirmacion$
DECLARE malos bigint;
BEGIN
    SELECT count(*) INTO malos
    FROM reportes.vista_reporte_corporativo r
    WHERE r.unidades_existencia <> (SELECT coalesce(sum(i.existencia_actual),0)
                                    FROM reportes.vw_inventarios_unificados i WHERE i.id_sede=r.id_sede)
       OR r.total_ventas <> (SELECT coalesce(sum(v.total_registrado),0)
                             FROM reportes.vw_pedidos_unificados v WHERE v.id_sede=r.id_sede
                             AND v.estado IN ('CONFIRMADO','COMPLETADO'));
    IF malos <> 0 THEN
        RAISE EXCEPTION 'Consolidado corporativo: % sede(s) no coinciden con sus fuentes.', malos;
    END IF;
END
$afirmacion$;
