BEGIN;

CREATE OR REPLACE VIEW reportes.src_catalogo_almacenes AS SELECT id_almacen::integer AS id_almacen, id_sede::integer AS id_sede, codigo_almacen::character varying(20) AS codigo_almacen, nombre::character varying(100) AS nombre, tipo_almacen::character varying(30) AS tipo_almacen, capacidad::numeric(12,2) AS capacidad, estado::character varying(20) AS estado FROM fuentes_reportes.almacenes;

CREATE OR REPLACE VIEW reportes.src_catalogo_categorias AS SELECT id_categoria::integer AS id_categoria, id_categoria_padre::integer AS id_categoria_padre, nombre::character varying(100) AS nombre, descripcion::text AS descripcion, estado::character varying(20) AS estado FROM fuentes_reportes.categorias;

CREATE OR REPLACE VIEW reportes.src_catalogo_clientes AS SELECT id_cliente::integer AS id_cliente, tipo_documento::character varying(20) AS tipo_documento, num_documento::character varying(30) AS num_documento, nombre_completo::character varying(150) AS nombre_completo, correo::character varying(100) AS correo, telefono::character varying(30) AS telefono, direccion::character varying(150) AS direccion, ciudad::character varying(50) AS ciudad, tipo_cliente::character varying(20) AS tipo_cliente, estado::character varying(20) AS estado FROM fuentes_reportes.clientes;

CREATE OR REPLACE VIEW reportes.src_catalogo_productos AS SELECT id_producto::integer AS id_producto, sku::character varying(50) AS sku, nombre::character varying(150) AS nombre, descripcion::text AS descripcion, id_categoria::integer AS id_categoria, unidad_medida::character varying(20) AS unidad_medida, precio_lista::numeric(12,2) AS precio_lista, marca::character varying(50) AS marca, estado::character varying(20) AS estado FROM fuentes_reportes.productos;

CREATE OR REPLACE VIEW reportes.src_catalogo_sedes AS SELECT id_sede::integer AS id_sede, codigo_sede::character varying(20) AS codigo_sede, nombre::character varying(100) AS nombre, ciudad::character varying(50) AS ciudad, departamento::character varying(50) AS departamento, direccion::character varying(150) AS direccion, telefono::character varying(30) AS telefono, tipo_sede::character varying(20) AS tipo_sede, estado::character varying(20) AS estado FROM fuentes_reportes.sedes;

CREATE OR REPLACE VIEW reportes.src_compras_detalle_orden_compra AS SELECT id_orden_compra::integer AS id_orden_compra, id_producto::integer AS id_producto, cantidad_solicitada::integer AS cantidad_solicitada, costo_unitario::numeric(12,2) AS costo_unitario FROM fuentes_reportes.detalle_orden_compra;

CREATE OR REPLACE VIEW reportes.src_compras_detalle_recepcion AS SELECT id_recepcion::integer AS id_recepcion, id_producto::integer AS id_producto, cantidad_recibida::integer AS cantidad_recibida FROM fuentes_reportes.detalle_recepcion;

CREATE OR REPLACE VIEW reportes.src_compras_ordenes_compra AS SELECT id_orden_compra::integer AS id_orden_compra, id_proveedor::integer AS id_proveedor, id_almacen_destino::integer AS id_almacen_destino, id_empleado::integer AS id_empleado, fecha_orden::timestamp without time zone AS fecha_orden, fecha_estimada::timestamp without time zone AS fecha_estimada, estado::character varying(20) AS estado, observaciones::text AS observaciones FROM fuentes_reportes.ordenes_compra;

CREATE OR REPLACE VIEW reportes.src_compras_recepciones_compra AS SELECT id_recepcion::integer AS id_recepcion, id_orden_compra::integer AS id_orden_compra, fecha_recepcion::timestamp without time zone AS fecha_recepcion, estado::character varying(20) AS estado, observaciones::text AS observaciones FROM fuentes_reportes.recepciones_compra;

CREATE OR REPLACE VIEW reportes.src_inventarios_detalle_transferencia AS SELECT id_transferencia::integer AS id_transferencia, id_producto::integer AS id_producto, cantidad_enviada::integer AS cantidad_enviada, cantidad_recibida::integer AS cantidad_recibida FROM fuentes_reportes.detalle_transferencia;

CREATE OR REPLACE VIEW reportes.src_inventarios_inventarios AS SELECT id_sede::integer AS id_sede, id_almacen::integer AS id_almacen, id_producto::integer AS id_producto, existencia_actual::integer AS existencia_actual, stock_minimo::integer AS stock_minimo, fecha_actualizacion::timestamp without time zone AS fecha_actualizacion FROM fuentes_reportes.inventarios;

CREATE OR REPLACE VIEW reportes.src_inventarios_transferencias AS SELECT id_transferencia::integer AS id_transferencia, id_almacen_origen::integer AS id_almacen_origen, id_almacen_destino::integer AS id_almacen_destino, fecha_solicitud::timestamp without time zone AS fecha_solicitud, fecha_despacho::timestamp without time zone AS fecha_despacho, fecha_recepcion::timestamp without time zone AS fecha_recepcion, estado::character varying(20) AS estado, observaciones::text AS observaciones FROM fuentes_reportes.transferencias;

CREATE OR REPLACE VIEW reportes.src_ventas_detalle_devolucion AS SELECT id_devolucion::integer AS id_devolucion, id_producto::integer AS id_producto, id_sede::integer AS id_sede, id_pedido::integer AS id_pedido, cantidad::integer AS cantidad, condicion_producto::character varying(30) AS condicion_producto FROM fuentes_reportes.detalle_devolucion;

CREATE OR REPLACE VIEW reportes.src_ventas_detalle_pedido AS SELECT id_sede::integer AS id_sede, id_pedido::integer AS id_pedido, id_producto::integer AS id_producto, cantidad::integer AS cantidad, precio_unitario::numeric(12,2) AS precio_unitario FROM fuentes_reportes.detalle_pedido;

CREATE OR REPLACE VIEW reportes.src_ventas_devoluciones AS SELECT id_devolucion::integer AS id_devolucion, id_sede::integer AS id_sede, id_pedido::integer AS id_pedido, fecha_solicitud::timestamp without time zone AS fecha_solicitud, motivo::text AS motivo, estado::character varying(20) AS estado FROM fuentes_reportes.devoluciones;

CREATE OR REPLACE VIEW reportes.src_ventas_pagos AS SELECT id_pago::integer AS id_pago, id_sede::integer AS id_sede, id_pedido::integer AS id_pedido, referencia_pago::character varying(50) AS referencia_pago, fecha_pago::timestamp without time zone AS fecha_pago, valor::numeric(12,2) AS valor, medio_pago::character varying(30) AS medio_pago, estado::character varying(20) AS estado FROM fuentes_reportes.pagos;

CREATE OR REPLACE VIEW reportes.src_ventas_pedidos_venta AS SELECT id_sede::integer AS id_sede, id_pedido::integer AS id_pedido, id_almacen::integer AS id_almacen, id_cliente::integer AS id_cliente, id_empleado::integer AS id_empleado, fecha_pedido::timestamp without time zone AS fecha_pedido, estado::character varying(20) AS estado, total_registrado::numeric(12,2) AS total_registrado, observaciones::text AS observaciones FROM fuentes_reportes.pedidos_venta;

CREATE OR REPLACE VIEW reportes.src_catalogo_proveedores AS SELECT id_proveedor, razon_social FROM fuentes_reportes.proveedores;

CREATE OR REPLACE VIEW reportes.src_identidad_empleados AS SELECT id_empleado, id_sede, nombre_completo FROM fuentes_reportes.empleados;

CREATE OR REPLACE VIEW reportes.vw_sedes AS SELECT id_sede::integer AS id_sede, codigo_sede::character varying AS codigo_sede, nombre_sede::character varying AS nombre_sede FROM (SELECT s.id_sede,s.codigo_sede,s.nombre AS nombre_sede FROM reportes.src_catalogo_sedes s) datos;

CREATE OR REPLACE VIEW reportes.vw_inventarios_unificados AS SELECT id_sede::integer AS id_sede, codigo_sede::character varying AS codigo_sede, nombre_sede::character varying AS nombre_sede, id_almacen::integer AS id_almacen, id_producto::integer AS id_producto, existencia_actual::integer AS existencia_actual, stock_minimo::integer AS stock_minimo, fecha_actualizacion::timestamp without time zone AS fecha_actualizacion FROM (SELECT s.id_sede,s.codigo_sede,s.nombre_sede,i.id_almacen,i.id_producto,i.existencia_actual,i.stock_minimo,i.fecha_actualizacion FROM reportes.src_inventarios_inventarios i JOIN reportes.vw_sedes s USING (id_sede)) datos;

CREATE OR REPLACE VIEW reportes.vw_pedidos_unificados AS SELECT id_sede::integer AS id_sede, codigo_sede::character varying AS codigo_sede, nombre_sede::character varying AS nombre_sede, id_pedido::integer AS id_pedido, id_almacen::integer AS id_almacen, id_cliente::integer AS id_cliente, id_empleado::integer AS id_empleado, fecha_pedido::timestamp without time zone AS fecha_pedido, estado::character varying AS estado, total_registrado::numeric AS total_registrado, observaciones::text AS observaciones FROM (SELECT s.id_sede,s.codigo_sede,s.nombre_sede,p.id_pedido,p.id_almacen,p.id_cliente,p.id_empleado,p.fecha_pedido,p.estado,p.total_registrado,p.observaciones FROM reportes.src_ventas_pedidos_venta p JOIN reportes.vw_sedes s USING (id_sede)) datos;

CREATE OR REPLACE VIEW reportes.vista_alertas_reabastecimiento AS
SELECT s.id_sede,
    s.nombre AS nombre_sede,
    a.id_almacen,
    a.nombre AS nombre_almacen,
    p.id_producto,
    p.sku,
    p.nombre AS nombre_producto,
    i.existencia_actual,
    i.stock_minimo,
    i.stock_minimo - i.existencia_actual AS faltante_minimo,
        CASE
            WHEN i.existencia_actual = 0 THEN 'SIN_EXISTENCIA'::text
            ELSE 'BAJO_MINIMO'::text
        END AS tipo_alerta
   FROM reportes.src_inventarios_inventarios i
     JOIN reportes.src_catalogo_sedes s ON s.id_sede = i.id_sede
     JOIN reportes.src_catalogo_almacenes a ON a.id_almacen = i.id_almacen AND a.id_sede = i.id_sede
     JOIN reportes.src_catalogo_productos p ON p.id_producto = i.id_producto
  WHERE i.existencia_actual = 0 OR i.existencia_actual < i.stock_minimo;

CREATE OR REPLACE VIEW reportes.vista_compras_pendientes AS
WITH recibido AS (
         SELECT rc.id_orden_compra,
            dr.id_producto,
            sum(dr.cantidad_recibida) AS cantidad_recibida
           FROM reportes.src_compras_recepciones_compra rc
             JOIN reportes.src_compras_detalle_recepcion dr ON dr.id_recepcion = rc.id_recepcion
          GROUP BY rc.id_orden_compra, dr.id_producto
        )
 SELECT oc.id_orden_compra,
    oc.estado AS estado_orden,
    doc.id_producto,
    p.nombre AS nombre_producto,
    doc.cantidad_solicitada,
    COALESCE(r.cantidad_recibida, 0::bigint) AS cantidad_recibida,
    doc.cantidad_solicitada - COALESCE(r.cantidad_recibida, 0::bigint) AS cantidad_pendiente
   FROM reportes.src_compras_detalle_orden_compra doc
     JOIN reportes.src_compras_ordenes_compra oc ON oc.id_orden_compra = doc.id_orden_compra
     LEFT JOIN recibido r ON r.id_orden_compra = doc.id_orden_compra AND r.id_producto = doc.id_producto
     LEFT JOIN reportes.src_catalogo_productos p ON p.id_producto = doc.id_producto
  WHERE oc.estado::text <> 'CANCELADA'::text AND (doc.cantidad_solicitada - COALESCE(r.cantidad_recibida, 0::bigint)) > 0;

CREATE OR REPLACE VIEW reportes.vista_devoluciones_por_producto AS
WITH vendido AS (
         SELECT src_ventas_detalle_pedido.id_producto,
            sum(src_ventas_detalle_pedido.cantidad) AS cantidad_vendida
           FROM reportes.src_ventas_detalle_pedido
          GROUP BY src_ventas_detalle_pedido.id_producto
        ), devuelto AS (
         SELECT dd.id_producto,
            sum(dd.cantidad) AS cantidad_devuelta
           FROM reportes.src_ventas_detalle_devolucion dd
             JOIN reportes.src_ventas_devoluciones d_1 ON d_1.id_devolucion = dd.id_devolucion
          WHERE d_1.estado::text = 'APROBADA'::text
          GROUP BY dd.id_producto
        )
 SELECT p.id_producto,
    p.nombre AS nombre_producto,
    COALESCE(v.cantidad_vendida, 0::bigint) AS cantidad_vendida,
    COALESCE(d.cantidad_devuelta, 0::bigint) AS cantidad_devuelta,
        CASE
            WHEN COALESCE(v.cantidad_vendida, 0::bigint) = 0 THEN NULL::numeric
            ELSE round(100.0 * COALESCE(d.cantidad_devuelta, 0::bigint)::numeric / v.cantidad_vendida::numeric, 2)
        END AS porcentaje_devolucion
   FROM reportes.src_catalogo_productos p
     LEFT JOIN vendido v ON v.id_producto = p.id_producto
     LEFT JOIN devuelto d ON d.id_producto = p.id_producto
  WHERE v.id_producto IS NOT NULL OR d.id_producto IS NOT NULL;

CREATE OR REPLACE VIEW reportes.vista_inventario_por_sede AS
SELECT s.id_sede,
    s.nombre AS nombre_sede,
    a.id_almacen,
    a.nombre AS nombre_almacen,
    p.id_producto,
    p.sku,
    p.nombre AS nombre_producto,
    i.existencia_actual,
    i.stock_minimo,
    i.fecha_actualizacion
   FROM reportes.src_inventarios_inventarios i
     JOIN reportes.src_catalogo_sedes s ON s.id_sede = i.id_sede
     JOIN reportes.src_catalogo_almacenes a ON a.id_almacen = i.id_almacen AND a.id_sede = i.id_sede
     JOIN reportes.src_catalogo_productos p ON p.id_producto = i.id_producto;

CREATE OR REPLACE VIEW reportes.vista_pedidos_pendientes AS
SELECT s.id_sede,
    s.nombre AS nombre_sede,
    pv.id_pedido,
    pv.fecha_pedido,
    c.id_cliente,
    c.nombre_completo AS cliente,
    pv.total_registrado
   FROM reportes.src_ventas_pedidos_venta pv
     JOIN reportes.src_catalogo_sedes s ON s.id_sede = pv.id_sede
     JOIN reportes.src_catalogo_clientes c ON c.id_cliente = pv.id_cliente
  WHERE pv.estado::text = 'PENDIENTE'::text;

CREATE OR REPLACE VIEW reportes.vista_productos_sin_inventario AS
SELECT p.id_producto,p.sku,p.nombre AS nombre_producto,p.estado,s.id_sede,s.nombre AS nombre_sede
FROM reportes.src_catalogo_productos p CROSS JOIN reportes.src_catalogo_sedes s
WHERE p.estado='ACTIVO' AND NOT EXISTS (
    SELECT 1 FROM reportes.src_inventarios_inventarios i
    WHERE i.id_producto=p.id_producto AND i.id_sede=s.id_sede
);

CREATE OR REPLACE VIEW reportes.vista_reporte_corporativo AS
WITH ventas AS (
    SELECT id_sede, sum(total_registrado) FILTER (WHERE estado IN ('CONFIRMADO', 'COMPLETADO')) AS total,
           count(*) FILTER (WHERE estado='PENDIENTE') AS pendientes
    FROM reportes.src_ventas_pedidos_venta GROUP BY id_sede
), pagos AS (
    SELECT id_sede, sum(valor) AS total FROM reportes.src_ventas_pagos
    WHERE estado='CONFIRMADO' GROUP BY id_sede
), inventario AS (
    SELECT i.id_sede, sum(i.existencia_actual) AS unidades,
           count(DISTINCT i.id_producto) FILTER (WHERE i.existencia_actual<i.stock_minimo) AS bajo_minimo,
           count(DISTINCT i.id_producto) FILTER (WHERE p.estado='ACTIVO') AS activos
    FROM reportes.src_inventarios_inventarios i
    LEFT JOIN reportes.src_catalogo_productos p USING (id_producto)
    GROUP BY i.id_sede
), compras AS (
    SELECT a.id_sede, count(*) AS ordenes,
           count(*) FILTER (WHERE o.estado IN ('PENDIENTE','PARCIAL')) AS pendientes
    FROM reportes.src_compras_ordenes_compra o
    JOIN reportes.src_catalogo_almacenes a ON a.id_almacen=o.id_almacen_destino
    WHERE o.estado<>'CANCELADA' GROUP BY a.id_sede
), transferencias AS (
    SELECT a.id_sede, count(*) AS recibidas_o_enviadas,
           count(*) FILTER (WHERE t.estado='EN_TRANSITO') AS en_transito
    FROM reportes.src_inventarios_transferencias t
    JOIN reportes.src_catalogo_almacenes a ON a.id_almacen=t.id_almacen_destino
    WHERE t.estado<>'CANCELADA' GROUP BY a.id_sede
)
SELECT s.id_sede,s.nombre AS nombre_sede,coalesce(v.total,0) AS total_ventas,
       coalesce(p.total,0) AS total_pagos,coalesce(v.pendientes,0) AS pedidos_pendientes,
       coalesce(i.unidades,0) AS unidades_existencia,coalesce(i.bajo_minimo,0) AS productos_bajo_minimo,
       coalesce(i.activos,0) AS productos_activos,coalesce(c.ordenes,0) AS ordenes_compra,
       coalesce(c.pendientes,0) AS compras_pendientes,coalesce(t.recibidas_o_enviadas,0) AS transferencias_destino,
       coalesce(t.en_transito,0) AS transferencias_en_transito
FROM reportes.src_catalogo_sedes s
LEFT JOIN ventas v USING (id_sede) LEFT JOIN pagos p USING (id_sede)
LEFT JOIN inventario i USING (id_sede) LEFT JOIN compras c USING (id_sede)
LEFT JOIN transferencias t USING (id_sede);

CREATE OR REPLACE VIEW reportes.vista_saldos_pendientes AS
WITH pagos_confirmados AS (
         SELECT src_ventas_pagos.id_sede,
            src_ventas_pagos.id_pedido,
            sum(src_ventas_pagos.valor) AS pagado
           FROM reportes.src_ventas_pagos
          WHERE src_ventas_pagos.estado::text = 'CONFIRMADO'::text
          GROUP BY src_ventas_pagos.id_sede, src_ventas_pagos.id_pedido
        )
 SELECT pv.id_sede,
    pv.id_pedido,
    pv.estado,
    pv.total_registrado,
    COALESCE(pc.pagado, 0::numeric) AS pagado_confirmado,
    pv.total_registrado - COALESCE(pc.pagado, 0::numeric) AS saldo_pendiente
   FROM reportes.src_ventas_pedidos_venta pv
     LEFT JOIN pagos_confirmados pc ON pc.id_sede = pv.id_sede AND pc.id_pedido = pv.id_pedido
  WHERE pv.estado::text <> 'CANCELADO'::text AND (pv.total_registrado - COALESCE(pc.pagado, 0::numeric)) > 0::numeric;

CREATE OR REPLACE VIEW reportes.vista_transferencias_en_transito AS
SELECT t.id_transferencia,
    t.fecha_despacho,
    t.estado,
    ao.id_almacen AS id_almacen_origen,
    ao.nombre AS almacen_origen,
    ad.id_almacen AS id_almacen_destino,
    ad.nombre AS almacen_destino,
    dt.id_producto,
    p.nombre AS nombre_producto,
    dt.cantidad_enviada,
    dt.cantidad_recibida
   FROM reportes.src_inventarios_transferencias t
     JOIN reportes.src_inventarios_detalle_transferencia dt ON dt.id_transferencia = t.id_transferencia
     JOIN reportes.src_catalogo_almacenes ao ON ao.id_almacen = t.id_almacen_origen
     JOIN reportes.src_catalogo_almacenes ad ON ad.id_almacen = t.id_almacen_destino
     LEFT JOIN reportes.src_catalogo_productos p ON p.id_producto = dt.id_producto
  WHERE t.fecha_despacho IS NOT NULL AND t.fecha_recepcion IS NULL AND t.estado::text <> 'CANCELADA'::text;

CREATE OR REPLACE VIEW reportes.vista_ventas_mensuales_por_sede AS
SELECT s.id_sede,
    s.nombre AS nombre_sede,
    date_trunc('month'::text, pv.fecha_pedido) AS mes,
    count(*) AS pedidos,
    sum(pv.total_registrado) AS total_ventas
   FROM reportes.src_ventas_pedidos_venta pv
     JOIN reportes.src_catalogo_sedes s ON s.id_sede = pv.id_sede
  WHERE pv.estado::text = ANY (ARRAY['CONFIRMADO'::character varying, 'COMPLETADO'::character varying]::text[])
  GROUP BY s.id_sede, s.nombre, (date_trunc('month'::text, pv.fecha_pedido));

COMMIT;
