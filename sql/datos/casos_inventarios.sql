-- Escenario sintético para la consulta 14.
BEGIN;
LOCK TABLE inventarios.transferencias IN SHARE ROW EXCLUSIVE MODE;
WITH creada AS (
    INSERT INTO inventarios.transferencias
        (id_transferencia, id_almacen_origen, id_almacen_destino, fecha_solicitud,
         fecha_despacho, fecha_recepcion, estado, observaciones)
    SELECT (SELECT max(id_transferencia)+1 FROM inventarios.transferencias),
           t.id_almacen_origen, t.id_almacen_destino, date '2026-10-25',
           date '2026-10-26', date '2026-10-28', 'RECIBIDA', 'DEMO-DIFERENCIA-RECEPCION'
    FROM inventarios.transferencias t
    WHERE NOT EXISTS (
        SELECT FROM inventarios.transferencias WHERE observaciones='DEMO-DIFERENCIA-RECEPCION'
    )
    AND EXISTS (SELECT FROM inventarios.detalle_transferencia d WHERE d.id_transferencia=t.id_transferencia)
    ORDER BY t.id_transferencia LIMIT 1
    RETURNING id_transferencia
)
INSERT INTO inventarios.detalle_transferencia
    (id_transferencia,id_producto,cantidad_enviada,cantidad_recibida)
SELECT c.id_transferencia, (SELECT min(id_producto) FROM inventarios.detalle_transferencia), 10, 8
FROM creada c;
COMMIT;
