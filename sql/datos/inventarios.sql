BEGIN;
-- Verificar las tablas existentes
SELECT table_schema, table_name
FROM information_schema.tables
WHERE table_schema = 'inventarios'
  AND table_type = 'BASE TABLE'
ORDER BY table_name;

-- 1. Generar inventarios
INSERT INTO inventarios.inventarios (
    id_sede,
    id_almacen,
    id_producto,
    existencia_actual,
    stock_minimo,
    fecha_actualizacion
)
SELECT
    a.id_sede,
    a.id_almacen,
    p.id_producto,
    CASE
        WHEN a.id_sede = 1 AND p.id_producto IN (16, 23, 30) THEN 0
        WHEN a.id_sede = 2 AND p.id_producto % 11 = 0 THEN 4
        ELSE 50 + ((p.id_producto * a.id_almacen) % 100)
    END,
    10 + (p.id_producto % 10),
    TIMESTAMP '2026-10-31 18:00:00'
FROM (
    VALUES
        (1, 1),
        (2, 2),
        (3, 3),
        (4, 4)
) AS a(id_sede, id_almacen)
CROSS JOIN generate_series(1, 80) AS p(id_producto);

-- 2. Generar transferencias
INSERT INTO inventarios.transferencias (
    id_transferencia,
    id_almacen_origen,
    id_almacen_destino,
    fecha_solicitud,
    fecha_despacho,
    fecha_recepcion,
    estado,
    observaciones
)
SELECT
    g,
    ((g - 1) % 4) + 1,
    (g % 4) + 1,
    DATE '2026-07-01' + (g * 3),
    DATE '2026-07-01' + (g * 3) + 1,
    CASE WHEN g <= 7 THEN NULL ELSE DATE '2026-07-01' + (g * 3) + 3 END,
    CASE WHEN g <= 7 THEN 'EN_TRANSITO' ELSE 'RECIBIDA' END,
    'Transferencia de prueba ' || g
FROM generate_series(1, 25) AS g;

-- 3. Generar detalles de transferencia
INSERT INTO inventarios.detalle_transferencia (
    id_transferencia,
    id_producto,
    cantidad_enviada,
    cantidad_recibida
)
SELECT
    g,
    ((g * 2 + n - 3) % 80) + 1,
    5 + n,
    CASE WHEN g <= 7 THEN NULL ELSE 5 + n END
FROM generate_series(1, 25) AS g
CROSS JOIN generate_series(1, 2) AS n;

-- 4. Verificar resultados
SELECT COUNT(*) AS total_inventarios
FROM inventarios.inventarios;

SELECT COUNT(*) AS total_transferencias
FROM inventarios.transferencias;

SELECT COUNT(*) AS total_detalles_transferencia
FROM inventarios.detalle_transferencia;
COMMIT;
