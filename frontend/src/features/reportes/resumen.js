import { permitePantalla, sesionActual } from '../../app/sesion.js';
import { listarInventario, sedes } from '../inventarios/datos.js';
import { clasificar } from '../inventarios/estados.js';

const indicadores = document.querySelector('#indicadores');
const filas = document.querySelector('#filas-sedes');
const estadoResumen = document.querySelector('#estado-resumen');
const formato = new Intl.NumberFormat('es-CO');
const permiteDetalle = permitePantalla(sesionActual(), 'index.html');

function consolidar(registros) {
  const totales = { unidades: 0, bajo: 0, agotado: 0, ausente: 0 };

  for (const registro of registros) {
    totales.unidades += registro.existencia ?? 0;

    const estado = clasificar(registro);
    if (estado !== 'disponible') {
      totales[estado]++;
    }
  }

  return totales;
}

function crearTarjeta(titulo, valor, estado) {
  const tarjeta = document.createElement('article');
  tarjeta.className = 'card';

  const etiqueta = document.createElement('span');
  const punto = document.createElement('i');
  punto.className = 'dot ' + estado;
  punto.setAttribute('aria-hidden', 'true');
  etiqueta.append(punto, titulo);

  const cantidad = document.createElement('strong');
  cantidad.textContent = formato.format(valor);

  tarjeta.append(etiqueta, cantidad);
  return tarjeta;
}

function crearFila({ sede, resumen }) {
  const fila = document.createElement('tr');
  const nombre = document.createElement('th');
  nombre.scope = 'row';
  nombre.textContent = sede.nombre;
  fila.append(nombre);

  for (const valor of [
    resumen.unidades, resumen.bajo, resumen.agotado, resumen.ausente,
  ]) {
    const celda = document.createElement('td');
    celda.className = 'number';
    celda.textContent = formato.format(valor);
    fila.append(celda);
  }

  const detalle = document.createElement('td');
  fila.append(detalle);
  if (!permiteDetalle) {
    detalle.textContent = '—';
    return fila;
  }

  const enlace = document.createElement('a');
  enlace.className = 'enlace-detalle';
  enlace.href = './index.html?sede=' + encodeURIComponent(sede.id);
  enlace.textContent = 'Ver inventario →';
  enlace.setAttribute('aria-label', 'Ver inventario de ' + sede.nombre);
  detalle.append(enlace);

  return fila;
}

async function cargarResumen() {
  try {
    const resultados = await Promise.all(sedes.map(async sede => ({
      sede,
      registros: await listarInventario(sede.id),
    })));

    const total = consolidar(resultados.flatMap(item => item.registros));
    const resumenPorSede = resultados.map(({ sede, registros }) => ({
      sede,
      resumen: consolidar(registros),
    }));

    // Prioriza las sedes con más agotados. Desempata por stock bajo.
    resumenPorSede.sort((a, b) =>
      b.resumen.agotado - a.resumen.agotado ||
      b.resumen.bajo - a.resumen.bajo ||
      a.sede.nombre.localeCompare(b.sede.nombre, 'es-CO')
    );

    indicadores.replaceChildren(
      crearTarjeta('Unidades registradas', total.unidades, 'disponible'),
      crearTarjeta('Referencias bajo mínimo', total.bajo, 'bajo'),
      crearTarjeta('Referencias agotadas', total.agotado, 'agotado'),
      crearTarjeta('Referencias sin registro', total.ausente, 'ausente'),
    );

    filas.replaceChildren(...resumenPorSede.map(crearFila));
    estadoResumen.textContent = resumenPorSede.length + ' sedes';
  } catch {
    estadoResumen.textContent = 'No se pudo cargar el inventario multisede.';
  }
}

await cargarResumen();