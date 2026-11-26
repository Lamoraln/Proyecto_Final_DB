-- Un resultado de cero en cada control indica que se conservan los IDs compartidos.
SELECT 'Inventario: producto, sede y almacén válidos' AS control, count(*) AS incumplimientos
FROM reportes.src_inventarios_inventarios i
LEFT JOIN reportes.src_catalogo_productos p USING (id_producto)
LEFT JOIN reportes.src_catalogo_almacenes a USING (id_sede,id_almacen)
WHERE p.id_producto IS NULL OR a.id_almacen IS NULL
UNION ALL
SELECT 'Pedidos: cliente, almacén y empleado de la sede', count(*)
FROM reportes.src_ventas_pedidos_venta v
LEFT JOIN reportes.src_catalogo_clientes c USING (id_cliente)
LEFT JOIN reportes.src_catalogo_almacenes a USING (id_sede,id_almacen)
LEFT JOIN reportes.src_identidad_empleados e USING (id_sede,id_empleado)
WHERE c.id_cliente IS NULL OR a.id_almacen IS NULL OR e.id_empleado IS NULL
UNION ALL
SELECT 'Compras: proveedor, almacén y empleado válidos', count(*)
FROM reportes.src_compras_ordenes_compra o
LEFT JOIN reportes.src_catalogo_proveedores p USING (id_proveedor)
LEFT JOIN reportes.src_catalogo_almacenes a ON a.id_almacen=o.id_almacen_destino
LEFT JOIN reportes.src_identidad_empleados e USING (id_empleado)
WHERE p.id_proveedor IS NULL OR a.id_almacen IS NULL OR e.id_empleado IS NULL
UNION ALL
SELECT 'Transferencias: almacenes de origen y destino válidos', count(*)
FROM reportes.src_inventarios_transferencias t
LEFT JOIN reportes.src_catalogo_almacenes a ON a.id_almacen=t.id_almacen_origen
LEFT JOIN reportes.src_catalogo_almacenes b ON b.id_almacen=t.id_almacen_destino
WHERE a.id_almacen IS NULL OR b.id_almacen IS NULL;
