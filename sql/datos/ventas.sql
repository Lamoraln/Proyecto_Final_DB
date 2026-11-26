BEGIN;
-- Verificar las tablas existentes
SELECT table_schema, table_name
FROM information_schema.tables
WHERE table_schema = 'ventas'
  AND table_type = 'BASE TABLE'
ORDER BY table_name;

-- 1. Generar pedidos de venta
INSERT INTO ventas.pedidos_venta (
    id_pedido,
    id_sede,
    id_almacen,
    id_cliente,
    id_empleado,
    fecha_pedido,
    estado,
    total_registrado
)
SELECT
    g,
    ((g - 1) / 100) + 1,
    ((g - 1) / 100) + 1,
    ((g - 1) % 100) + 1,
    ((g - 1) % 5) + 1
        + (((g - 1) / 100) * 5),
    DATE '2026-07-01' + (g % 123),
    CASE
        WHEN g % 20 = 0 THEN 'CANCELADO'
        WHEN g % 10 = 0 THEN 'PENDIENTE'
        ELSE 'COMPLETADO'
    END,
    0
FROM generate_series(1, 300) AS g;

-- 2. Generar detalles de pedidos
INSERT INTO ventas.detalle_pedido (
    id_sede,
    id_pedido,
    id_producto,
    cantidad,
    precio_unitario
)
SELECT
    p.id_sede,
    p.id_pedido,
    ((p.id_pedido + n * 7 - 2) % 80) + 1,
    1 + (p.id_pedido % 5),
    50000 + (((p.id_pedido + n) % 80) * 2500)
FROM (
    SELECT id_sede, id_pedido
    FROM ventas.pedido_venta_sede_01

    UNION ALL

    SELECT id_sede, id_pedido
    FROM ventas.pedido_venta_sede_02

    UNION ALL

    SELECT id_sede, id_pedido
    FROM ventas.pedido_venta_sede_03
) AS p
CROSS JOIN generate_series(1, 3) AS n;

-- 3. Actualizar los totales de los pedidos
UPDATE ventas.pedidos_venta p
SET total_registrado = (
    SELECT SUM(d.cantidad * d.precio_unitario)
    FROM ventas.detalle_pedido d
    WHERE (d.id_sede, d.id_pedido) = (p.id_sede, p.id_pedido)
);

-- 4. Generar pagos
INSERT INTO ventas.pagos (
    id_pago,
    id_sede,
    id_pedido,
    referencia_pago,
    fecha_pago,
    valor,
    medio_pago,
    estado
)
SELECT
    ROW_NUMBER() OVER (
        ORDER BY p.id_sede, p.id_pedido
    )::INTEGER,
    p.id_sede,
    p.id_pedido,
    'PAGO-' || LPAD(
        ROW_NUMBER() OVER (
            ORDER BY p.id_sede, p.id_pedido
        )::TEXT,
        5,
        '0'
    ),
    DATE '2026-07-01' +
        (
            ROW_NUMBER() OVER (
                ORDER BY p.id_sede, p.id_pedido
            )::INTEGER % 123
        ) + 1,
    p.total_registrado,
    CASE
        WHEN ROW_NUMBER() OVER (
            ORDER BY p.id_sede, p.id_pedido
        ) % 3 = 0 THEN 'EFECTIVO'
        WHEN ROW_NUMBER() OVER (
            ORDER BY p.id_sede, p.id_pedido
        ) % 3 = 1 THEN 'TARJETA'
        ELSE 'TRANSFERENCIA'
    END,
    CASE
        WHEN p.estado = 'CANCELADO' THEN 'RECHAZADO'
        WHEN p.estado = 'PENDIENTE' THEN 'PENDIENTE'
        ELSE 'CONFIRMADO'
    END
FROM (
    SELECT id_sede, id_pedido, total_registrado, estado
    FROM ventas.pedido_venta_sede_01

    UNION ALL

    SELECT id_sede, id_pedido, total_registrado, estado
    FROM ventas.pedido_venta_sede_02

    UNION ALL

    SELECT id_sede, id_pedido, total_registrado, estado
    FROM ventas.pedido_venta_sede_03
) AS p;

-- 5. Generar devoluciones
WITH pedidos AS (
    SELECT id_sede, id_pedido
    FROM ventas.pedido_venta_sede_01

    UNION ALL

    SELECT id_sede, id_pedido
    FROM ventas.pedido_venta_sede_02

    UNION ALL

    SELECT id_sede, id_pedido
    FROM ventas.pedido_venta_sede_03
),
pedidos_numerados AS (
    SELECT
        ROW_NUMBER() OVER (
            ORDER BY id_sede, id_pedido
        )::INTEGER AS numero,
        id_sede,
        id_pedido
    FROM pedidos
)
INSERT INTO ventas.devoluciones (
    id_devolucion,
    id_sede,
    id_pedido,
    fecha_solicitud,
    motivo,
    estado
)
SELECT
    numero,
    id_sede,
    id_pedido,
    DATE '2026-10-01' + (numero % 20),
    'Motivo de devolucion de prueba ' || numero,
    'APROBADA'
FROM pedidos_numerados
WHERE numero <= 20;

-- 6. Generar detalles de devolución
INSERT INTO ventas.detalle_devolucion (
    id_devolucion,
    id_producto,
    id_sede,
    id_pedido,
    cantidad,
    condicion_producto
)
SELECT
    d.id_devolucion,
    producto.id_producto,
    d.id_sede,
    d.id_pedido,
    1,
    CASE
        WHEN d.id_devolucion % 2 = 0 THEN 'BUEN_ESTADO'
        ELSE 'DANADO'
    END
FROM ventas.devoluciones d
JOIN LATERAL (
    SELECT dp.id_producto
    FROM ventas.detalle_pedido dp
    WHERE dp.id_sede = d.id_sede
      AND dp.id_pedido = d.id_pedido
    ORDER BY dp.id_producto
    LIMIT 1
) producto ON TRUE
ORDER BY d.id_devolucion;

-- 7. Verificar resultados
SELECT COUNT(*) AS total_pedidos
FROM ventas.pedidos_venta;

SELECT COUNT(*) AS total_detalles
FROM ventas.detalle_pedido;

SELECT COUNT(*) AS total_pagos
FROM ventas.pagos;

SELECT COUNT(*) AS total_devoluciones
FROM ventas.devoluciones;

SELECT COUNT(*) AS total_detalles_devolucion
FROM ventas.detalle_devolucion;
COMMIT;
