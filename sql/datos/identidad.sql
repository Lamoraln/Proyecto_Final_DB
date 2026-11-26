BEGIN;
-- Verificar las tablas existentes
SELECT table_schema, table_name
FROM information_schema.tables
WHERE table_schema = 'identidad'
  AND table_type = 'BASE TABLE'
ORDER BY table_name;

-- 1. Generar empleados
INSERT INTO identidad.empleados (
    id_empleado, id_sede, cargo, tipo_documento,
    num_documento, nombre_completo, correo,
    telefono, fecha_contratacion, estado
)
SELECT
    g,
    ((g - 1) / 5) + 1,
    CASE
        WHEN g % 5 = 1 THEN 'GERENTE'
        WHEN g % 5 = 2 THEN 'VENDEDOR'
        WHEN g % 5 = 3 THEN 'RESPONSABLE DE INVENTARIO'
        WHEN g % 5 = 4 THEN 'RESPONSABLE DE COMPRAS'
        ELSE 'AUXILIAR'
    END,
    'CC',
    '800000' || LPAD(g::TEXT, 4, '0'),
    'Empleado ' || g,
    'empleado' || g || '@ejemplo.com',
    '320000' || LPAD(g::TEXT, 4, '0'),
    DATE '2026-01-01' + (g * 2),
    'ACTIVO'
FROM generate_series(1, 20) AS g;

-- 2. Generar usuarios
INSERT INTO identidad.usuarios (
    id_usuario, id_empleado, nombre_usuario,
    password_hash, rol, estado, fecha_creacion
)
SELECT
    g,
    g,
    'usuario' || g,
    'HASH_DE_PRUEBA_CAMBIAR',
    CASE
        WHEN g = 1 THEN 'ADMINISTRADOR'
        WHEN g <= 3 THEN 'GERENCIA'
        WHEN g <= 8 THEN 'RESP_INVENTARIO'
        WHEN g <= 13 THEN 'RESP_COMPRAS'
        WHEN g <= 18 THEN 'VENDEDOR'
        ELSE 'AUDITOR'
    END,
    'ACTIVO',
    TIMESTAMP '2026-07-01 08:00:00'
        + (g * INTERVAL '1 day')
FROM generate_series(1, 20) AS g;

-- 3. Generar auditorías
INSERT INTO identidad.auditoria_accesos (
    id_auditoria, id_usuario, fecha_hora,
    accion, objeto_consultado, resultado
)
SELECT
    g,
    ((g - 1) % 20) + 1,
    TIMESTAMP '2026-07-01 08:00:00'
        + (g * INTERVAL '2 days'),
    CASE
        WHEN g % 3 = 0 THEN 'INSERT'
        WHEN g % 3 = 1 THEN 'SELECT'
        ELSE 'UPDATE'
    END,
    CASE
        WHEN g % 4 = 0 THEN 'productos'
        WHEN g % 4 = 1 THEN 'pedidos_venta'
        WHEN g % 4 = 2 THEN 'inventarios'
        ELSE 'clientes'
    END,
    CASE
        WHEN g % 10 = 0 THEN 'DENEGADO'
        ELSE 'PERMITIDO'
    END
FROM generate_series(1, 40) AS g;

-- 4. Verificar resultados
SELECT COUNT(*) AS total_empleados
FROM identidad.empleados;

SELECT COUNT(*) AS total_usuarios
FROM identidad.usuarios;

SELECT COUNT(*) AS total_auditorias
FROM identidad.auditoria_accesos;
COMMIT;
