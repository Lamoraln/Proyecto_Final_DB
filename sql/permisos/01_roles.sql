-- Ejecutar en cada instancia. Las cuentas de conexión se aprovisionan por separado.
DO $roles$
DECLARE
    nombre text;
BEGIN
    FOREACH nombre IN ARRAY ARRAY['rol_administrador', 'rol_gerencia', 'rol_resp_inventario',
        'rol_resp_compras', 'rol_vendedor', 'rol_auditor']
    LOOP
        IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = nombre) THEN
            EXECUTE format('CREATE ROLE %I NOLOGIN', nombre);
        END IF;
    END LOOP;
END
$roles$;
