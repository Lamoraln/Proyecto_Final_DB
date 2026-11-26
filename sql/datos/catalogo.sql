BEGIN;
-- Verificar las tablas existentes
SELECT table_schema, table_name
FROM information_schema.tables
WHERE table_schema = 'catalogo'
  AND table_type = 'BASE TABLE'
ORDER BY table_name;

-- 1. Generar sedes
INSERT INTO catalogo.sedes (
    id_sede, codigo_sede, nombre, ciudad,
    departamento, direccion, telefono,
    tipo_sede, estado
)
VALUES
(1, 'SED-NOR', 'Sede Norte', 'Bogota', 'Cundinamarca',
 'Calle 100 # 15-20', '6011111111', 'VENTA', 'ACTIVA'),

(2, 'SED-CEN', 'Sede Centro', 'Bogota', 'Cundinamarca',
 'Carrera 10 # 20-30', '6012222222', 'VENTA', 'ACTIVA'),

(3, 'SED-SUR', 'Sede Sur', 'Bogota', 'Cundinamarca',
 'Avenida Caracas # 45-60', '6013333333', 'VENTA', 'ACTIVA'),

(4, 'SED-DIS', 'Centro de Distribucion', 'Bogota',
 'Cundinamarca', 'Zona Industrial', '6014444444',
 'DISTRIBUCION', 'ACTIVA');

-- 2. Generar almacenes
INSERT INTO catalogo.almacenes (
    id_almacen, id_sede, codigo_almacen,
    nombre, tipo_almacen, capacidad, estado
)
VALUES
(1, 1, 'ALM-NOR', 'Almacen Norte', 'PRINCIPAL', 10000, 'ACTIVO'),
(2, 2, 'ALM-CEN', 'Almacen Centro', 'PRINCIPAL', 10000, 'ACTIVO'),
(3, 3, 'ALM-SUR', 'Almacen Sur', 'PRINCIPAL', 10000, 'ACTIVO'),
(4, 4, 'ALM-DIS', 'Almacen Distribucion', 'DISTRIBUCION', 50000, 'ACTIVO');

-- 3. Generar categorías
INSERT INTO catalogo.categorias (
    id_categoria, id_categoria_padre,
    nombre, descripcion, estado
)
VALUES
(1, NULL, 'Electronica', 'Productos electronicos', 'ACTIVA'),
(2, NULL, 'Computacion', 'Equipos y accesorios informaticos', 'ACTIVA'),
(3, NULL, 'Hogar', 'Productos para el hogar', 'ACTIVA'),
(4, NULL, 'Oficina', 'Productos para oficina', 'ACTIVA'),
(5, NULL, 'Accesorios', 'Accesorios generales', 'ACTIVA');

-- 4. Generar productos
INSERT INTO catalogo.productos (
    id_producto, sku, nombre, descripcion,
    id_categoria, unidad_medida, precio_lista,
    marca, estado
)
SELECT
    g,
    'SKU-' || LPAD(g::TEXT, 4, '0'),
    'Producto ' || g,
    'Producto de prueba numero ' || g,
    ((g - 1) % 5) + 1,
    'UNIDAD',
    50000 + (g * 2500),
    'Marca ' || (((g - 1) % 10) + 1),
    'ACTIVO'
FROM generate_series(1, 80) AS g;

-- 5. Generar proveedores
INSERT INTO catalogo.proveedores (
    id_proveedor, identificacion, tipo_identificacion,
    razon_social, ciudad, direccion, correo,
    telefono, estado
)
SELECT
    g,
    '900000' || LPAD(g::TEXT, 4, '0'),
    'NIT',
    'Proveedor ' || g || ' SAS',
    'Bogota',
    'Direccion proveedor ' || g,
    'proveedor' || g || '@ejemplo.com',
    '300000' || LPAD(g::TEXT, 4, '0'),
    'ACTIVO'
FROM generate_series(1, 10) AS g;

-- 6. Generar relaciones producto-proveedor
INSERT INTO catalogo.producto_proveedor (
    id_producto, id_proveedor, costo_referencia,
    plazo_entrega_dias, proveedor_preferido
)
SELECT
    p.id_producto,
    v.id_proveedor,
    p.precio_lista * 0.65,
    3 + v.id_proveedor,
    v.id_proveedor = (((p.id_producto - 1) % 10) + 1)
FROM catalogo.productos p
CROSS JOIN LATERAL (
    SELECT ((p.id_producto - 1) % 10) + 1 AS id_proveedor
    UNION ALL
    SELECT ((p.id_producto + 2) % 10) + 1
) v;

-- 7. Generar clientes
INSERT INTO catalogo.clientes (
    id_cliente, tipo_documento, num_documento,
    nombre_completo, correo, telefono,
    direccion, ciudad, tipo_cliente, estado
)
SELECT
    g,
    'CC',
    '100000' || LPAD(g::TEXT, 4, '0'),
    'Cliente de prueba ' || g,
    'cliente' || g || '@ejemplo.com',
    '310000' || LPAD(g::TEXT, 4, '0'),
    'Direccion cliente ' || g,
    'Bogota',
    CASE
        WHEN g % 5 = 0 THEN 'JURIDICO'
        ELSE 'NATURAL'
    END,
    'ACTIVO'
FROM generate_series(1, 100) AS g;

-- 8. Verificar resultados
SELECT COUNT(*) AS total_sedes
FROM catalogo.sedes;

SELECT COUNT(*) AS total_almacenes
FROM catalogo.almacenes;

SELECT COUNT(*) AS total_categorias
FROM catalogo.categorias;

SELECT COUNT(*) AS total_productos
FROM catalogo.productos;

SELECT COUNT(*) AS total_proveedores
FROM catalogo.proveedores;

SELECT COUNT(*) AS total_producto_proveedor
FROM catalogo.producto_proveedor;

SELECT COUNT(*) AS total_clientes
FROM catalogo.clientes;
COMMIT;
