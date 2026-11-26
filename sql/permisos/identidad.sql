BEGIN;
GRANT CONNECT ON DATABASE db_identidad TO rol_gerencia, rol_auditor;
GRANT USAGE ON SCHEMA identidad TO rol_gerencia, rol_auditor;
GRANT CONNECT ON DATABASE db_identidad TO rol_administrador;
GRANT USAGE, CREATE ON SCHEMA identidad TO rol_administrador;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA identidad TO rol_administrador;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA identidad TO rol_administrador;
REVOKE INSERT, UPDATE, DELETE, TRUNCATE ON ALL TABLES IN SCHEMA identidad
    FROM rol_gerencia, rol_auditor, rol_resp_inventario, rol_resp_compras, rol_vendedor;
REVOKE SELECT ON identidad.usuarios FROM rol_gerencia, rol_auditor, rol_resp_inventario, rol_resp_compras, rol_vendedor;
GRANT SELECT ON identidad.empleados, identidad.auditoria_accesos TO rol_gerencia, rol_auditor;
COMMIT;
