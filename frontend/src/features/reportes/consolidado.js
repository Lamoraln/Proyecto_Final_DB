import { consultar } from '../../shared/api.js';
import { montarDirectorio, mostrarErrorConsulta } from '../../shared/directorio.js';

const contenedor = document.querySelector('#tabla-consolidado');
const moneda = new Intl.NumberFormat('es-CO', { style: 'currency', currency: 'COP' });

try {
  const reporte = await consultar('reportes/consolidado');
  montarDirectorio(contenedor, [{
    titulo: 'Todas las sedes',
    columnas: [
      'Sede', 'Productos activos con inventario', 'Unidades', 'Ventas confirmadas',
      'Pedidos pendientes', 'Compras abiertas', 'Traslados en tránsito',
    ],
    filas: reporte.map(r => [
      r.nombre_sede, r.productos_activos, r.unidades_existencia, moneda.format(r.total_ventas),
      r.pedidos_pendientes, r.compras_pendientes, r.transferencias_en_transito,
    ]),
  }], 'Alcance');
} catch (error) {
  mostrarErrorConsulta(contenedor, error);
}
