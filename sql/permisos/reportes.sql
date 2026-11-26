BEGIN;
GRANT CONNECT ON DATABASE db_reportes TO rol_administrador, rol_gerencia, rol_auditor;
GRANT USAGE ON SCHEMA reportes TO rol_administrador, rol_gerencia, rol_auditor;
GRANT SELECT ON reportes.vista_inventario_por_sede, reportes.vista_alertas_reabastecimiento, reportes.vista_productos_sin_inventario, reportes.vista_ventas_mensuales_por_sede, reportes.vista_pedidos_pendientes, reportes.vista_saldos_pendientes, reportes.vista_compras_pendientes, reportes.vista_transferencias_en_transito, reportes.vista_devoluciones_por_producto, reportes.vista_reporte_corporativo
    TO rol_administrador, rol_gerencia, rol_auditor;
REVOKE INSERT, UPDATE, DELETE, TRUNCATE ON ALL TABLES IN SCHEMA reportes
    FROM rol_gerencia, rol_auditor, rol_resp_inventario, rol_resp_compras, rol_vendedor;
COMMIT;
