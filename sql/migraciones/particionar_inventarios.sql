-- Conversión de la tabla existente. Conserva los datos anteriores como respaldo privado.
-- Ejecutar con el propietario de la tabla y con las escrituras de la aplicación detenidas.
BEGIN;
SET LOCAL lock_timeout = '8s';
LOCK TABLE inventarios.inventarios IN ACCESS EXCLUSIVE MODE;
DO $migracion$
DECLARE
    origen regclass := 'inventarios.inventarios'::regclass;
    objeto record;
    principal text;
BEGIN
    IF EXISTS (SELECT 1 FROM pg_partitioned_table WHERE partrelid = origen) THEN
        RETURN;
    END IF;

    IF EXISTS (SELECT FROM pg_trigger WHERE tgrelid = origen AND NOT tgisinternal)
        OR EXISTS (SELECT FROM pg_policy WHERE polrelid = origen)
        OR EXISTS (SELECT FROM pg_class WHERE oid = origen AND relrowsecurity)
        OR EXISTS (
            SELECT FROM pg_depend d JOIN pg_rewrite w ON w.oid = d.objid
            WHERE d.classid = 'pg_rewrite'::regclass AND d.refobjid = origen
        )
        OR EXISTS (
            SELECT FROM pg_constraint WHERE conrelid = origen AND contype = 'f'
        ) THEN
        RAISE EXCEPTION 'Hay dependencias locales que requieren una migración específica.';
    END IF;

    CREATE SCHEMA IF NOT EXISTS respaldo_distribured;
    REVOKE ALL ON SCHEMA respaldo_distribured FROM PUBLIC;
    CREATE TABLE inventarios.inventarios_part
        (LIKE inventarios.inventarios INCLUDING ALL) PARTITION BY LIST (id_sede);
    CREATE TABLE inventarios.inventario_sede_01 PARTITION OF inventarios.inventarios_part FOR VALUES IN (1);
    CREATE TABLE inventarios.inventario_sede_02 PARTITION OF inventarios.inventarios_part FOR VALUES IN (2);
    CREATE TABLE inventarios.inventario_sede_03 PARTITION OF inventarios.inventarios_part FOR VALUES IN (3);
    CREATE TABLE inventarios.inventario_sede_04 PARTITION OF inventarios.inventarios_part FOR VALUES IN (4);
    INSERT INTO inventarios.inventarios_part SELECT * FROM inventarios.inventarios;
    IF EXISTS (
        SELECT * FROM inventarios.inventarios
        EXCEPT ALL
        SELECT * FROM inventarios.inventarios_part
    ) OR (SELECT count(*) FROM inventarios.inventarios) <>
         (SELECT count(*) FROM inventarios.inventarios_part) THEN
        RAISE EXCEPTION 'Los datos de la tabla particionada no coinciden con el origen.';
    END IF;

    FOR objeto IN
        SELECT a.grantee, a.privilege_type, a.is_grantable
        FROM pg_class c CROSS JOIN LATERAL aclexplode(c.relacl) a
        WHERE c.oid = origen AND a.grantee <> c.relowner
    LOOP
        principal := CASE WHEN objeto.grantee = 0 THEN 'PUBLIC'
                          ELSE quote_ident(pg_get_userbyid(objeto.grantee)) END;
        EXECUTE format('GRANT %s ON inventarios.inventarios_part TO %s%s',
                       objeto.privilege_type, principal,
                       CASE WHEN objeto.is_grantable THEN ' WITH GRANT OPTION' ELSE '' END);
    END LOOP;

    ALTER TABLE inventarios.inventarios SET SCHEMA respaldo_distribured;
    ALTER TABLE inventarios.inventarios_part RENAME TO inventarios;

    -- Recrear y validar las FK entrantes contra la nueva tabla.
    FOR objeto IN
        SELECT conrelid::regclass AS dependiente, conname,
               replace(pg_get_constraintdef(oid),
                       'REFERENCES respaldo_distribured.inventarios(',
                       'REFERENCES inventarios.inventarios(') AS definicion
        FROM pg_constraint WHERE confrelid = origen AND contype = 'f'
    LOOP
        IF position('REFERENCES inventarios.inventarios(' IN objeto.definicion) = 0 THEN
            RAISE EXCEPTION 'No se pudo redirigir la FK %', objeto.conname;
        END IF;
        EXECUTE format('ALTER TABLE %s DROP CONSTRAINT %I, ADD CONSTRAINT %I %s',
            objeto.dependiente, objeto.conname, objeto.conname, objeto.definicion);
    END LOOP;

    IF EXISTS (SELECT FROM pg_constraint WHERE confrelid = origen AND contype = 'f') THEN
        RAISE EXCEPTION 'Una FK sigue apuntando al respaldo.';
    END IF;
END
$migracion$;
COMMIT;
