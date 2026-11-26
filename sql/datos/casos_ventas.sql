-- Escenario sintético para la consulta 07. Abona el 25 % de un pedido pendiente.
BEGIN;
LOCK TABLE ventas.pagos IN SHARE ROW EXCLUSIVE MODE;
INSERT INTO ventas.pagos
    (id_pago,id_sede,id_pedido,referencia_pago,fecha_pago,valor,medio_pago,estado)
SELECT (SELECT max(id_pago)+1 FROM ventas.pagos), p.id_sede,p.id_pedido,
       'DEMO-ABONO-PARCIAL', p.fecha_pedido, round(p.total_registrado/4,2),
       'TRANSFERENCIA','CONFIRMADO'
FROM ventas.pedidos_venta p
WHERE p.estado='PENDIENTE' AND p.total_registrado>=1
  AND NOT EXISTS (
    SELECT FROM ventas.pagos g WHERE g.id_sede=p.id_sede AND g.id_pedido=p.id_pedido
                                  AND g.estado='CONFIRMADO'
  )
ORDER BY p.id_sede,p.id_pedido LIMIT 1
ON CONFLICT (referencia_pago) DO NOTHING;
COMMIT;
