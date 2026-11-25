import { listarPedidosVenta } from './datos.js';
import { sedes } from '../inventarios/datos.js';
import { montarDirectorio, mostrarErrorConsulta } from '../../shared/directorio.js';

const devoluciones = [
  { codigo: 'DV-001', sedeId: 1, pedido: 'PV-001', sku: 'EM-104', cantidad: 2,
    estado: 'APROBADA', motivo: 'Empaque averiado' },
  { codigo: 'DV-002', sedeId: 1, pedido: 'PV-001', sku: 'EM-104', cantidad: 1,
    estado: 'APROBADA', motivo: 'Defecto en el producto' },
  { codigo: 'DV-003', sedeId: 1, pedido: 'PV-001', sku: 'EM-104', cantidad: 2,
    estado: 'SOLICITADA', motivo: 'Revisión de calidad' },
  { codigo: 'DV-004', sedeId: 2, pedido: 'PV-002', sku: 'OF-119', cantidad: 1,
    estado: 'RECHAZADA', motivo: 'Solicitud fuera de plazo' },
];

const contenedor = document.querySelector('#directorio');
const clave = (sedeId, pedido, sku) => JSON.stringify([sedeId, pedido, sku]);
const nombresSedes = new Map(sedes.map(sede => [sede.id, sede.nombre]));

try {
  const pedidos = await listarPedidosVenta();
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

    if (!linea) {
      throw new Error('La devolución referencia una línea inexistente: ' + devolucion.codigo);
    }

    if (devolucion.estado === 'APROBADA') {
      aprobadas.set(id, (aprobadas.get(id) ?? 0) + devolucion.cantidad);
    }

    return [
      devolucion.codigo, devolucion.pedido, nombresSedes.get(devolucion.sedeId),
      linea.producto, devolucion.cantidad, devolucion.estado, devolucion.motivo,
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