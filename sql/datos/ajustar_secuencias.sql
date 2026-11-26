-- Ejecutar en cada base operativa después de la carga con IDs explícitos.
-- La aplicación debe estar detenida durante la carga y el ajuste.
DO $secuencias$
DECLARE
    r record;
    maximo bigint;
    usado bigint;
BEGIN
    FOR r IN
        SELECT n.nspname esquema, c.relname tabla, a.attname columna,
               pg_get_serial_sequence(format('%I.%I',n.nspname,c.relname),a.attname) secuencia
        FROM pg_class c
        JOIN pg_namespace n ON n.oid=c.relnamespace
        JOIN pg_attribute a ON a.attrelid=c.oid AND a.attnum>0 AND NOT a.attisdropped
        WHERE c.relkind IN ('r','p') AND n.nspname IN ('catalogo','compras','inventarios','ventas','identidad')
    LOOP
        IF r.secuencia IS NULL THEN CONTINUE; END IF;
        EXECUTE format('SELECT max(%I) FROM %I.%I',r.columna,r.esquema,r.tabla) INTO maximo;
        EXECUTE format('SELECT last_value FROM %s',r.secuencia::regclass) INTO usado;
        IF maximo IS NOT NULL AND maximo>=usado THEN
            PERFORM setval(r.secuencia::regclass,maximo,true);
        END IF;
    END LOOP;
END
$secuencias$;
