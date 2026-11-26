BEGIN;
GRANT CONNECT ON DATABASE db_catalogo TO rol_administrador, rol_gerencia, rol_resp_inventario, rol_resp_compras, rol_vendedor, rol_auditor;
GRANT USAGE ON SCHEMA catalogo TO rol_administrador, rol_gerencia, rol_resp_inventario, rol_resp_compras, rol_vendedor, rol_auditor;
GRANT CONNECT ON DATABASE db_catalogo TO rol_administrador;
GRANT USAGE, CREATE ON SCHEMA catalogo TO rol_administrador;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA catalogo TO rol_administrador;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA catalogo TO rol_administrador;
REVOKE INSERT, UPDATE, DELETE, TRUNCATE ON ALL TABLES IN SCHEMA catalogo
    FROM rol_gerencia, rol_auditor, rol_resp_inventario, rol_resp_compras, rol_vendedor;
GRANT SELECT ON ALL TABLES IN SCHEMA catalogo TO rol_gerencia, rol_auditor;
GRANT SELECT ON catalogo.sedes, catalogo.almacenes, catalogo.categorias, catalogo.productos TO rol_resp_inventario, rol_resp_compras, rol_vendedor;
GRANT SELECT ON catalogo.proveedores, catalogo.producto_proveedor TO rol_resp_compras;
GRANT SELECT ON catalogo.clientes TO rol_vendedor;
COMMIT;
