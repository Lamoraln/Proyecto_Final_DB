import { consultar, indiceCatalogo } from '../../shared/api.js';
import { listarPedidosVenta } from './datos.js';
import { sedes } from '../inventarios/datos.js';
import { montarDirectorio, mostrarErrorConsulta } from '../../shared/directorio.js';

const contenedor = document.querySelector('#directorio');
const clave = (sedeId, pedido, sku) => JSON.stringify([sedeId, pedido, sku]);
const nombresSedes = new Map(sedes.map(sede => [sede.id, sede.nombre]));

try {
  const [pedidos, registros, productos] = await Promise.all([
    listarPedidosVenta(), consultar('ventas/devoluciones'),
    indiceCatalogo('productos', 'id_producto'),
  ]);
  const devoluciones = registros.map(r => ({
    codigo: 'DV-' + r.id_devolucion, sedeId: r.id_sede, pedido: 'PV-' + r.id_pedido,
    sku: productos.get(r.id_producto)?.sku ?? String(r.id_producto),
    producto: productos.get(r.id_producto)?.nombre ?? `Producto #${r.id_producto}`,
    cantidad: r.cantidad, estado: r.estado, motivo: r.motivo,
  }));
  const lineas = pedidos
    .filter(pedido => ['CONFIRMADO', 'COMPLETADO'].includes(pedido.estado))
    .flatMap(pedido => pedido.lineas.map(linea => ({
      ...linea,
      sedeId: pedido.sedeId,
      pedido: pedido.codigo,
    })));

  const porClave = new Map(lineas.map(linea => [
    clave(linea.sedeId, linea.pedido, linea.sku), linea,
  ]));
  const aprobadas = new Map();

  const historial = devoluciones.map(devolucion => {
    const id = clave(devolucion.sedeId, devolucion.pedido, devolucion.sku);
    const linea = porClave.get(id);

    if (devolucion.estado === 'APROBADA') {
      aprobadas.set(id, (aprobadas.get(id) ?? 0) + devolucion.cantidad);
    }

    return [
      devolucion.codigo, devolucion.pedido, nombresSedes.get(devolucion.sedeId),
      linea?.producto ?? devolucion.producto, devolucion.cantidad, devolucion.estado, devolucion.motivo,
    ];
  });

  montarDirectorio(contenedor, [
    {
      titulo: 'Historial de devoluciones',
      columnas: ['Devolución', 'Pedido', 'Sede', 'Producto', 'Unidades', 'Estado', 'Motivo'],
      filas: historial,
    },
    {
      titulo: 'Saldo devolvible por línea',
      columnas: ['Pedido', 'Sede', 'SKU', 'Producto', 'Vendidas', 'Aprobadas', 'Devolvibles'],
      filas: lineas.map(linea => {
        const cantidadDevuelta = aprobadas.get(clave(linea.sedeId, linea.pedido, linea.sku)) ?? 0;

        return [
          linea.pedido, nombresSedes.get(linea.sedeId), linea.sku, linea.producto,
          linea.cantidad, cantidadDevuelta, linea.cantidad - cantidadDevuelta,
        ];
      }),
    },
  ]);
} catch (error) {
  mostrarErrorConsulta(contenedor, error);
}