SELECT b.relname AS fragmento, pg_get_expr(b.relpartbound, b.oid) AS limite
FROM pg_inherits h JOIN pg_class b ON b.oid=h.inhrelid
WHERE h.inhparent='ventas.pedidos_venta'::regclass ORDER BY b.relname;

SELECT id_sede, tableoid::regclass AS fragmento, count(*) AS filas
FROM ventas.pedidos_venta GROUP BY 1,2 ORDER BY 1;
