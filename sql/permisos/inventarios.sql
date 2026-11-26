BEGIN;
GRANT CONNECT ON DATABASE db_inventario TO rol_gerencia, rol_auditor;
GRANT USAGE ON SCHEMA inventarios TO rol_gerencia, rol_auditor;
GRANT CONNECT ON DATABASE db_inventario TO rol_administrador;
GRANT USAGE, CREATE ON SCHEMA inventarios TO rol_administrador;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA inventarios TO rol_administrador;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA inventarios TO rol_administrador;
REVOKE INSERT, UPDATE, DELETE, TRUNCATE ON ALL TABLES IN SCHEMA inventarios
    FROM rol_gerencia, rol_auditor, rol_resp_inventario, rol_resp_compras, rol_vendedor;
GRANT SELECT ON ALL TABLES IN SCHEMA inventarios TO rol_gerencia, rol_auditor;
GRANT CONNECT ON DATABASE db_inventario TO rol_resp_inventario;
GRANT USAGE ON SCHEMA inventarios TO rol_resp_inventario;
GRANT SELECT, INSERT, UPDATE ON inventarios.inventarios, inventarios.transferencias, inventarios.detalle_transferencia TO rol_resp_inventario;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA inventarios TO rol_resp_inventario;
COMMIT;
