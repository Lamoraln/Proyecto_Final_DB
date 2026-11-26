-- Una fila por sede. Un resultado íntegro coincide con las sumas independientes.
WITH control AS (
    SELECT r.id_sede, r.unidades_existencia, r.total_ventas,
           (SELECT coalesce(sum(i.existencia_actual),0)
            FROM reportes.vw_inventarios_unificados i WHERE i.id_sede=r.id_sede) AS unidades_fuente,
           (SELECT coalesce(sum(v.total_registrado),0)
            FROM reportes.vw_pedidos_unificados v WHERE v.id_sede=r.id_sede
            AND v.estado IN ('CONFIRMADO','COMPLETADO')) AS ventas_fuente
    FROM reportes.vista_reporte_corporativo r
)
SELECT *, unidades_existencia=unidades_fuente AND total_ventas=ventas_fuente AS coincide
FROM control ORDER BY id_sede;

SELECT id_sede,count(*) AS registros,sum(existencia_actual) AS unidades
FROM reportes.vw_inventarios_unificados GROUP BY id_sede ORDER BY id_sede;
