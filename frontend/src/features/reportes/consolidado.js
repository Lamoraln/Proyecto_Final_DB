import { listarInventario, sedes } from '../inventarios/datos.js';
import { listarOrdenesCompra } from '../compras/datos.js';
import { listarPedidosVenta } from '../ventas/datos.js';
import { listarTransferencias } from '../transferencias/datos.js';
import { montarDirectorio, mostrarErrorConsulta } from '../../shared/directorio.js';

const contenedor = document.querySelector('#tabla-consolidado');
const moneda = new Intl.NumberFormat('es-CO', {
  style: 'currency',
  currency: 'COP',
  maximumFractionDigits: 2,
  minimumFractionDigits: 0,
});

try {
  const [inventarios, compras, pedidos, traslados] = await Promise.all([
    Promise.all(sedes.map(sede => listarInventario(sede.id))),
    listarOrdenesCompra(),
    listarPedidosVenta(),
    listarTransferencias(),
  ]);

  const filas = sedes.map((sede, indice) => {
    const inventario = inventarios[indice];
    const pedidosSede = pedidos.filter(pedido => pedido.sedeId === sede.id);

    const ventasConfirmadas = pedidosSede
      .filter(pedido => ['CONFIRMADO', 'COMPLETADO'].includes(pedido.estado))
      .flatMap(pedido => pedido.lineas)
      .reduce((total, linea) => total + linea.cantidad * linea.precioUnitario, 0);

    return [
      sede.nombre,
      new Set(inventario.filter(p => p.existencia !== null).map(p => p.sku)).size,
      inventario.reduce((suma, p) => suma + (p.existencia ?? 0), 0),
      moneda.format(ventasConfirmadas),
      pedidosSede.filter(pedido => pedido.estado === 'PENDIENTE').length,
      compras.filter(orden =>
        orden.sedeId === sede.id && ['PENDIENTE', 'PARCIAL'].includes(orden.estado),
      ).length,
      traslados.filter(traslado =>
        traslado.destino === sede.id && traslado.estado === 'EN_TRANSITO',
      ).length,
    ];
  });

  montarDirectorio(contenedor, [{
    titulo: 'Todas las sedes',
    columnas: [
      'Sede', 'Referencias registradas', 'Unidades', 'Ventas confirmadas',
      'Pedidos pendientes', 'Compras abiertas', 'Traslados por llegar',
    ],
    filas,
  }], 'Alcance');
} catch (error) {
  mostrarErrorConsulta(contenedor, error);
}