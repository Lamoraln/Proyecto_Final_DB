-- Pruebas 1 a 4. Esta transacción deja los datos como estaban.
BEGIN;
DO $pruebas$
DECLARE
    producto integer;
    categoria integer := (SELECT min(id_categoria) FROM catalogo.categorias);
    categoria_inexistente integer := (SELECT max(id_categoria) + 1 FROM catalogo.categorias);
    sku_prueba text := 'PRUEBA-' || txid_current();
BEGIN
    SELECT max(id_producto) + 1 INTO producto FROM catalogo.productos;
    INSERT INTO catalogo.productos
        (id_producto, sku, nombre, id_categoria, unidad_medida, precio_lista, estado)
    VALUES (producto, sku_prueba, 'Producto de verificación', categoria, 'UND', 1, 'ACTIVO');
    IF NOT EXISTS (SELECT FROM catalogo.productos WHERE id_producto = producto AND sku = sku_prueba) THEN
        RAISE EXCEPTION 'No se encontró el producto insertado.';
    END IF;

    BEGIN
        INSERT INTO catalogo.productos
            (id_producto, sku, nombre, id_categoria, unidad_medida, precio_lista, estado)
        VALUES (producto+1, sku_prueba, 'SKU duplicado', categoria, 'UND', 1, 'ACTIVO');
        RAISE EXCEPTION 'UNIQUE aceptó un SKU duplicado.';
    EXCEPTION WHEN unique_violation THEN
        RAISE NOTICE 'SKU duplicado rechazado: %', SQLSTATE;
    END;

    BEGIN
        UPDATE catalogo.productos SET precio_lista = -1 WHERE id_producto = producto;
        RAISE EXCEPTION 'CHECK aceptó un precio negativo.';
    EXCEPTION WHEN check_violation THEN
        RAISE NOTICE 'Precio negativo rechazado: %', SQLSTATE;
    END;

    BEGIN
        UPDATE catalogo.productos SET id_categoria = categoria_inexistente WHERE id_producto = producto;
        RAISE EXCEPTION 'FK aceptó una categoría inexistente.';
    EXCEPTION WHEN foreign_key_violation THEN
        RAISE NOTICE 'Categoría inexistente rechazada: %', SQLSTATE;
    END;
END
$pruebas$;
SELECT id_producto, sku, nombre FROM catalogo.productos WHERE sku = 'PRUEBA-' || txid_current();
ROLLBACK;
