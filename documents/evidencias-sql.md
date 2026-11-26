# Resultados verificados de DistribuRed

## Datos y distribución

Resultados de la auditoría en las seis instancias Neon del proyecto. Las
consultas de conteo se ejecutaron contra sus bases propietarias.

| Conjunto | Resultado |
|---|---:|
| Sedes / centros de distribución / almacenes | 4 / 1 / 4 |
| Productos / categorías / proveedores / clientes | 81 / 5 / 10 / 100 |
| Empleados | 20 |
| Pedidos / líneas de pedido | 300 / 900 |
| Órdenes de compra / recepciones | 60 / 55 |
| Transferencias / devoluciones | 26 / 20 |
| Meses con compras y ventas | 4 |

Los 81 productos y 26 traslados incluyen un escenario sintético adicional para
probar ausencias y diferencias de recepción. Se añadió también un abono parcial
sintético. Las tablas originales de inventarios y pedidos se conservaron en el
esquema privado de respaldo al migrar.

| Sede | Inventarios en fragmento | Pedidos en fragmento | Unidades consolidadas | Ventas consolidadas |
|---|---:|---:|---:|---:|
| 1 | 80 | 100 | 4251 | 421250000,00 |
| 2 | 80 | 100 | 4052 | 423875000,00 |
| 3 | 80 | 100 | 3934 | 424562500,00 |
| 4 | 80 | 0 | 4221 | 0,00 |
| Total | 320 | 300 | 16458 | 1269687500,00 |

El fragmento de pedidos de la sede 4 existe y queda vacío. La distribución de
las filas se verificó con `tableoid` y los límites con `pg_inherits`. Las
unidades y las ventas del consolidado coincidieron con las sumas calculadas
directamente sobre las dos vistas unificadas en las cuatro sedes.

## Veinte consultas obligatorias

Se ejecutó el SQL de [20_consultas.sql](../sql/reportes/20_consultas.sql) en
Neon. El número de filas corresponde a la salida de cada consulta, sin publicar
registros de clientes o empleados.

| Consulta | Filas | Interpretación del resultado |
|---|---:|---|
| 01. Inventario valorizado | 320 | Un registro por sede, almacén y producto, valorizado al precio de lista. |
| 02. Alertas | 38 | Registros agotados o por debajo de su mínimo. |
| 03. Productos ausentes | 4 | El producto sintético sin existencias no tiene registro en ninguna de las cuatro sedes. |
| 04. Ranking | 60 | Cinco referencias por sede comercial y mes, con desempate por ID. |
| 05. Variación mensual | 16 | Cuatro meses por cada sede, incluidos meses sin ventas. |
| 06. Clientes multisede | 100 | Cada resultado tiene compras efectivas en, al menos, dos sedes. |
| 07. Saldos pendientes | 30 | Se encontró un saldo con un abono confirmado parcial. |
| 08. Pedidos diversos | 300 | Cada pedido reportado tiene al menos tres productos distintos. |
| 09. Pendientes antiguos | 30 | Superan 30 días al corte del 31 de octubre de 2026. |
| 10. Demanda superior a existencias | 3 | Líneas pendientes que requieren más unidades que las registradas en su almacén. |
| 11. Cumplimiento de proveedores | 10 | Un resumen por proveedor con órdenes, puntualidad y retraso medio. |
| 12. Compras pendientes | 46 | Líneas de compra con saldo sin recibir. |
| 13. Traslados en tránsito | 14 | Líneas despachadas y aún sin recepción. |
| 14. Diferencias de recepción | 1 | El caso sintético envió 10 unidades y recibió 8. |
| 15. Redistribución | 101 | Pares origen–destino con excedente y déficit del mismo producto. |
| 16. Baja rotación | 80 | Registros con stock positivo sin venta efectiva en la ventana de 90 días. |
| 17. Devoluciones | 80 | Indicadores por referencia y categoría durante el periodo de prueba. |
| 18. Surtido | 80 | INTERSECT encontró 80 productos disponibles en ambas sedes. EXCEPT no encontró productos exclusivos de la primera. |
| 19. Vendedores | 15 | Clasificación por monto vendido dentro de su sede. |
| 20. Consolidado | 4 | Un resultado por sede. Coincide con las cantidades independientes de las tablas de origen. |

Las diez vistas obligatorias ejecutaron sin errores. Sus cardinalidades están
cubiertas por las consultas y por los conteos específicos de vistas unificadas:
320 inventarios, 300 pedidos y 4 sedes. El repositorio también contiene pruebas de
integridad para montos de pedidos, pagos, devoluciones y recepciones. Los
controles ejecutados devolvieron cero referencias inválidas o excesos.

## Matriz de pruebas

| Prueba y SQL | Esperado | Obtenido |
|---|---|---|
| Inserción y consulta de producto, `catalogo.sql` | Inserción visible en la transacción | Aprobó en Neon y los datos temporales se revirtieron |
| SKU duplicado, `catalogo.sql` | 23505 | Rechazado por UNIQUE |
| Existencia negativa, `inventarios.sql` | 23514 | Rechazado por CHECK |
| Categoría inexistente, `catalogo.sql` | 23503 | Rechazada por FK |
| Fragmentos de sedes, `inventarios.sql` y `fragmentos_ventas.sql` | Particiones disjuntas | 4 particiones de inventario y 4 de ventas |
| Vista unificada, `reportes.sql` | Cobertura de 4 sedes | 320 filas de inventario repartidas entre las 4 sedes |
| CTE y ventanas, consultas 04, 05, 19 y 20 | Ranking y comparación temporal | 60, 16, 15 y 4 filas |
| Operaciones de conjuntos, consulta 18 | Diferencias e intersección | 0 exclusivos de sede 1 y 80 compartidos |
| Roles, `roles_inventario.sql` | SELECT y UPDATE permitidos al responsable; SELECT permitido y UPDATE y DELETE denegados a Gerencia | Ejecutado en PostgreSQL local sobre las concesiones del repositorio. En Neon se comprobó la misma matriz efectiva con `has_schema_privilege` y `has_table_privilege`. La cuenta de la conexión no tiene habilitado SET ROLE en Inventarios |
| Consolidado, `reportes.sql` | Totales sin multiplicación de filas | Las cuatro sedes coinciden con los totales de origen |

La instalación limpia, carga sintética, vistas y 20 consultas también se
comprobaron en un PostgreSQL local embebido. Esa prueba usó los mismos esquemas
en un solo proceso para validar SQL y datos, mientras que la integración remota
se verificó por separado en Neon mediante las tablas foráneas.

## Conclusiones y límites

El particionamiento concentra cada conjunto por sede dentro de su servicio.
La integración consulta los datos en sus instancias propietarias mediante
lectores con alcance definido. El consolidado agrega inventarios, pedidos,
pagos, compras y traslados antes de combinar los resultados por sede.

Las vistas requieren disponibilidad de sus fuentes. Las referencias distribuidas
se revisan mediante consultas de control. La verificación de roles demuestra
privilegios por objeto; la autorización por sede para usuarios web es una etapa
posterior. Se puede ampliar la entrega con políticas por fila y automatización
de las pruebas sin cambiar la condición de fragmentación.
