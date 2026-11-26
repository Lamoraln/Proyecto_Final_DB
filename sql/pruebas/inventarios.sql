-- Fragmentación física y rechazo de cantidad negativa.
SELECT id_sede, tableoid::regclass AS fragmento, count(*) AS filas
FROM inventarios.inventarios GROUP BY 1, 2 ORDER BY 1;

DO $prueba$
BEGIN
    BEGIN
        UPDATE inventarios.inventarios SET existencia_actual=-1
        WHERE (id_sede,id_almacen,id_producto) = (
            SELECT id_sede,id_almacen,id_producto FROM inventarios.inventarios LIMIT 1
        );
        RAISE EXCEPTION 'No se obtuvo el rechazo esperado para la cantidad negativa.';
    EXCEPTION WHEN check_violation THEN
        RAISE NOTICE 'Cantidad negativa rechazada: %', SQLSTATE;
    END;
END
$prueba$;
