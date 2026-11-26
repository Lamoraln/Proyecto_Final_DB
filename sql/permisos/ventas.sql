BEGIN;
GRANT CONNECT ON DATABASE db_ventas TO rol_gerencia, rol_auditor;
GRANT USAGE ON SCHEMA ventas TO rol_gerencia, rol_auditor;
GRANT CONNECT ON DATABASE db_ventas TO rol_administrador;
GRANT USAGE, CREATE ON SCHEMA ventas TO rol_administrador;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA ventas TO rol_administrador;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA ventas TO rol_administrador;
REVOKE INSERT, UPDATE, DELETE, TRUNCATE ON ALL TABLES IN SCHEMA ventas
    FROM rol_gerencia, rol_auditor, rol_resp_inventario, rol_resp_compras, rol_vendedor;
GRANT SELECT ON ALL TABLES IN SCHEMA ventas TO rol_gerencia, rol_auditor;
GRANT CONNECT ON DATABASE db_ventas TO rol_vendedor;
GRANT USAGE ON SCHEMA ventas TO rol_vendedor;
GRANT SELECT, INSERT, UPDATE ON ventas.pedidos_venta, ventas.detalle_pedido, ventas.pagos TO rol_vendedor;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA ventas TO rol_vendedor;
COMMIT;
