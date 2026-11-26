-- Escenario sintético para la consulta 03. Ejecutar después de cargar Catálogo.
BEGIN;
LOCK TABLE catalogo.productos IN SHARE ROW EXCLUSIVE MODE;
INSERT INTO catalogo.productos
    (id_producto, sku, nombre, id_categoria, unidad_medida, precio_lista, estado)
SELECT (SELECT max(id_producto)+1 FROM catalogo.productos),
       'DEMO-SIN-INVENTARIO', 'Producto de prueba sin inventario',
       (SELECT min(id_categoria) FROM catalogo.categorias), 'UND', 1000, 'ACTIVO'
ON CONFLICT (sku) DO NOTHING;
COMMIT;
