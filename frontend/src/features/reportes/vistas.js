import { consultar } from '../../shared/api.js';
import { montarDirectorio } from '../../shared/directorio.js';

const selector = document.querySelector('#vista-sql');
const resultado = document.querySelector('#resultado-vista');
const vistas = {
  inventario_por_sede: 'Inventario por sede',
  alertas_reabastecimiento: 'Alertas de reabastecimiento',
  productos_sin_inventario: 'Productos sin inventario',
  ventas_mensuales_por_sede: 'Ventas mensuales',
  pedidos_pendientes: 'Pedidos pendientes',
  saldos_pendientes: 'Saldos pendientes',
  compras_pendientes: 'Compras pendientes',
  transferencias_en_transito: 'Transferencias en tránsito',
  devoluciones_por_producto: 'Devoluciones por producto',
  reporte_corporativo: 'Reporte corporativo',
};

for (const [clave, nombre] of Object.entries(vistas)) {
  selector.add(new Option(nombre, clave));
}

let carga = 0;
selector.addEventListener('change', async () => {
  const version = ++carga;
  const seleccion = selector.value;
  resultado.textContent = seleccion ? 'Consultando vista…' : '';
  if (!seleccion) return;

  try {
    const vista = await consultar('reportes/vistas/' + encodeURIComponent(seleccion));
    if (version !== carga) return;

    montarDirectorio(resultado, [{
      titulo: vistas[seleccion],
      columnas: vista.columnas.map(columna => columna.replaceAll('_', ' ')),
      filas: vista.filas.map(fila => vista.columnas.map(columna => fila[columna])),
    }], 'Vista activa');
  } catch (error) {
    if (version === carga) resultado.textContent = error.message;
  }
});
