import { listarTransferencias } from './datos.js';
import { todasLasSedes } from '../inventarios/datos.js';

const filtroEstado = document.querySelector('#estado');
const filtroDestino = document.querySelector('#destino');
const listado = document.querySelector('#traslados');
const conteo = document.querySelector('#conteo');
const sedesPorId = new Map(todasLasSedes.map(sede => [sede.id, sede]));

const estados = {
  EN_TRANSITO: 'En tránsito',
  RECIBIDA: 'Recibida',
};

function crear(etiqueta, texto = '', clase = '') {
  const elemento = document.createElement(etiqueta);
  elemento.textContent = texto;
  if (clase) elemento.className = clase;
  return elemento;
}

function mostrarFecha(fecha) {
  if (!fecha) return 'Pendiente';
  const [anio, mes, dia] = fecha.split('-');
  return [dia, mes, anio].join('/');
}

function nombreAlmacen(idSede) {
  const sede = sedesPorId.get(idSede);
  return sede ? sede.nombre + ' · ' + sede.almacen : 'Almacén sin identificar';
}

function crearTabla(traslado) {
  const tabla = document.createElement('table');
  tabla.setAttribute('aria-label', 'Productos de ' + traslado.codigo);

  const encabezado = tabla.createTHead().insertRow();
  for (const titulo of ['Producto', 'Enviada', 'Recibida', 'Diferencia']) {
    const columna = crear('th', titulo);
    columna.scope = 'col';
    encabezado.append(columna);
  }

  const cuerpo = tabla.createTBody();

  for (const producto of traslado.productos) {
    const fila = cuerpo.insertRow();
    const diferencia = producto.recibida === null
      ? '—'
      : String(producto.recibida - producto.enviada);

    fila.append(
      crear('td', producto.nombre + ' · ' + producto.sku),
      crear('td', producto.enviada),
      crear('td', producto.recibida ?? 'Pendiente'),
      crear('td', diferencia),
    );
  }

  const contenedor = crear('div', '', 'table-wrap');
  contenedor.append(tabla);
  return contenedor;
}

function crearTraslado(traslado) {
  const detalle = crear('details', '', 'traslado');
  const cabecera = document.createElement('summary');
  const texto = document.createElement('span');

  texto.append(
    crear('strong', traslado.codigo),
    crear('small', nombreAlmacen(traslado.origen) + ' → ' + nombreAlmacen(traslado.destino)),
  );

  const enTransito = traslado.estado === 'EN_TRANSITO';
  const tieneDiferencias = traslado.productos.some(
    producto => producto.recibida !== null && producto.recibida !== producto.enviada,
  );

  const indicadores = crear('span', '', 'traslado-estados');
  indicadores.append(crear(
    'span',
    estados[traslado.estado],
    enTransito ? 'badge bajo' : 'badge disponible',
  ));

  if (tieneDiferencias) {
    indicadores.append(crear('span', 'Con diferencia', 'badge agotado'));
  }

  cabecera.append(texto, indicadores);

  detalle.append(
    cabecera,
    crear(
      'p',
      'Despacho: ' + mostrarFecha(traslado.despacho) +
      ' · Recepción: ' + mostrarFecha(traslado.recepcion),
      'traslado-fechas',
    ),
    crearTabla(traslado),
  );

  return detalle;
}

function renderizar(transferencias) {
  const visibles = transferencias.filter(traslado =>
    (!filtroEstado.value || traslado.estado === filtroEstado.value) &&
    (!filtroDestino.value || traslado.destino === Number(filtroDestino.value)),
  );

  conteo.textContent = visibles.length + ' de ' + transferencias.length + ' traslados';

  if (visibles.length === 0) {
    listado.replaceChildren(crear('p', 'No hay traslados con estos filtros.', 'empty'));
    return;
  }

  listado.replaceChildren(...visibles.map(crearTraslado));
}

try {
  const transferencias = await listarTransferencias();
  const destinos = new Set(transferencias.map(traslado => traslado.destino));
  for (const sede of todasLasSedes) {
    if (destinos.has(sede.id)) filtroDestino.add(new Option(sede.nombre, sede.id));
  }

  filtroEstado.addEventListener('change', () => renderizar(transferencias));
  filtroDestino.addEventListener('change', () => renderizar(transferencias));

  renderizar(transferencias);
} catch (error) {
  console.error('Error al cargar las transferencias', error);
  conteo.textContent = 'No se pudieron cargar los traslados.';
}