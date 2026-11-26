BEGIN;
-- Verificar las tablas existentes
SELECT table_schema, table_name
FROM information_schema.tables
WHERE table_schema = 'compras'
  AND table_type = 'BASE TABLE'
ORDER BY table_name;

-- 1. Generar órdenes de compra
INSERT INTO compras.ordenes_compra (
    id_orden_compra,
    id_proveedor,
    id_almacen_destino,
    id_empleado,
    fecha_orden,
    fecha_estimada,
    estado,
    observaciones
)
SELECT
    g,
    ((g - 1) % 10) + 1,
    ((g - 1) % 4) + 1,
    ((g - 1) % 20) + 1,
    DATE '2026-07-01' + (g * 2),
    DATE '2026-07-01' + (g * 2) + 7,
    CASE
        WHEN g <= 30 THEN 'RECIBIDA'
        WHEN g <= 55 THEN 'PARCIAL'
        ELSE 'PENDIENTE'
    END,
    'Orden de compra de prueba ' || g
FROM generate_series(1, 60) AS g;

-- 2. Generar detalles de órdenes de compra
INSERT INTO compras.detalle_orden_compra (
    id_orden_compra,
    id_producto,
    cantidad_solicitada,
    costo_unitario
)
SELECT
    g,
    CASE
        WHEN n = 1 THEN ((g * 2 - 2) % 80) + 1
        ELSE ((g * 2 - 1) % 80) + 1
    END,
    10 + (g % 10),
    30000 + (g * 500)
FROM generate_series(1, 60) AS g
CROSS JOIN generate_series(1, 2) AS n;

-- 3. Generar recepciones
INSERT INTO compras.recepciones_compra (
    id_recepcion,
    id_orden_compra,
    fecha_recepcion,
    estado,
    observaciones
)
SELECT
    g,
    g,
    DATE '2026-07-01' + (g * 2) + CASE WHEN g % 5 = 0 THEN 10 ELSE 5 END,
    CASE
        WHEN g <= 30 THEN 'TOTAL'
        ELSE 'PARCIAL'
    END,
    'Recepcion de prueba ' || g
FROM generate_series(1, 55) AS g;

-- 4. Generar detalles de recepción
INSERT INTO compras.detalle_recepcion (
    id_recepcion,
    id_producto,
    cantidad_recibida
)
SELECT
    g,
    CASE
        WHEN n = 1 THEN ((g * 2 - 2) % 80) + 1
        ELSE ((g * 2 - 1) % 80) + 1
    END,
    CASE
        WHEN g <= 30 THEN 10 + (g % 10)
        ELSE 5
    END
FROM generate_series(1, 55) AS g
CROSS JOIN generate_series(1, 2) AS n;

-- 5. Verificar resultados
SELECT COUNT(*) AS total_ordenes
FROM compras.ordenes_compra;

SELECT COUNT(*) AS total_detalles_compra
FROM compras.detalle_orden_compra;

SELECT COUNT(*) AS total_recepciones
FROM compras.recepciones_compra;

SELECT COUNT(*) AS total_detalles_recepcion
FROM compras.detalle_recepcion;
COMMIT;
