BEGIN;
GRANT CONNECT ON DATABASE db_compras TO rol_gerencia, rol_auditor;
GRANT USAGE ON SCHEMA compras TO rol_gerencia, rol_auditor;
GRANT CONNECT ON DATABASE db_compras TO rol_administrador;
GRANT USAGE, CREATE ON SCHEMA compras TO rol_administrador;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA compras TO rol_administrador;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA compras TO rol_administrador;
REVOKE INSERT, UPDATE, DELETE, TRUNCATE ON ALL TABLES IN SCHEMA compras
    FROM rol_gerencia, rol_auditor, rol_resp_inventario, rol_resp_compras, rol_vendedor;
GRANT SELECT ON ALL TABLES IN SCHEMA compras TO rol_gerencia, rol_auditor;
GRANT CONNECT ON DATABASE db_compras TO rol_resp_compras;
GRANT USAGE ON SCHEMA compras TO rol_resp_compras;
GRANT SELECT, INSERT, UPDATE ON compras.ordenes_compra, compras.detalle_orden_compra, compras.recepciones_compra, compras.detalle_recepcion TO rol_resp_compras;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA compras TO rol_resp_compras;
COMMIT;
