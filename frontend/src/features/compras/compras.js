import { sedes } from '../inventarios/datos.js';
import { listarOrdenesCompra } from './datos.js';

const filtroSede = document.querySelector('#sede-compra');
const filtroEstado = document.querySelector('#estado-compra');
const listado = document.querySelector('#ordenes');
const conteo = document.querySelector('#conteo');
const sedesPorId = new Map(sedes.map(sede => [sede.id, sede]));
const formatoCantidad = new Intl.NumberFormat('es-CO');

const estados = {
  PENDIENTE: { nombre: 'Pendiente', clase: 'badge ausente' },
  PARCIAL: { nombre: 'Parcial', clase: 'badge bajo' },
  RECIBIDA: { nombre: 'Recibida', clase: 'badge disponible' },
  CANCELADA: { nombre: 'Cancelada', clase: 'badge agotado' },
};

function crear(etiqueta, texto = '', clase = '') {
  const elemento = document.createElement(etiqueta);
  elemento.textContent = texto;
  if (clase) elemento.className = clase;
  return elemento;
}

function resumirLineas(orden) {
  const recibidoPorSku = new Map();

  for (const recepcion of orden.recepciones) {
    for (const linea of recepcion.lineas) {
      const acumulado = recibidoPorSku.get(linea.sku) ?? 0;
      recibidoPorSku.set(linea.sku, acumulado + linea.cantidad);
    }
  }

  return orden.lineas.map(linea => {
    const recibida = recibidoPorSku.get(linea.sku) ?? 0;

    return {
      ...linea,
      recibida,
      pendiente: orden.estado === 'CANCELADA'
        ? null
        : linea.solicitada - recibida,
    };
  });
}

function crearTabla(orden) {
  const contenedor = crear('div', '', 'table-wrap');
  contenedor.tabIndex = 0;
  contenedor.setAttribute('role', 'region');
  contenedor.setAttribute('aria-label', 'Detalle de ' + orden.codigo);

  const tabla = document.createElement('table');
  const encabezado = tabla.createTHead().insertRow();
  const columnas = ['Producto', 'Solicitada', 'Recibida', 'Pendiente'];

  for (const [indice, titulo] of columnas.entries()) {
    const columna = crear('th', titulo, indice > 0 ? 'number' : '');
    columna.scope = 'col';
    encabezado.append(columna);
  }

  const cuerpo = tabla.createTBody();

  for (const linea of resumirLineas(orden)) {
    const fila = cuerpo.insertRow();
    const producto = crear('th', linea.producto);
    producto.scope = 'row';
    producto.append(crear('small', linea.sku));

    fila.append(
      producto,
      crear('td', formatoCantidad.format(linea.solicitada), 'number'),
      crear('td', formatoCantidad.format(linea.recibida), 'number'),
      crear(
        'td',
        linea.pendiente === null ? 'No aplica' : formatoCantidad.format(linea.pendiente),
        'number',
      ),
    );
  }

  contenedor.append(tabla);
  return contenedor;
}

function crearOrden(orden) {
  const detalle = crear('details', '', 'traslado');
  const cabecera = document.createElement('summary');
  const texto = document.createElement('span');
  const sede = sedesPorId.get(orden.sedeId);
  const destino = sede
    ? sede.nombre + ' · ' + orden.almacen
    : orden.almacen;
  const estado = estados[orden.estado];
  const fecha = orden.fechaEstimada.split('-').reverse().join('/');

  texto.append(
    crear('strong', orden.codigo + ' · ' + orden.proveedor),
    crear('small', destino + ' · Entrega estimada ' + fecha),
  );

  cabecera.append(texto, crear('span', estado.nombre, estado.clase));

  detalle.append(
    cabecera,
    crear(
      'p',
      'Recepciones registradas: ' + orden.recepciones.length,
      'traslado-fechas',
    ),
    crearTabla(orden),
  );

  return detalle;
}

function renderizar(ordenes) {
  const visibles = ordenes.filter(orden =>
    (!filtroSede.value || orden.sedeId === Number(filtroSede.value)) &&
    (!filtroEstado.value || orden.estado === filtroEstado.value),
  );

  conteo.textContent = visibles.length + ' de ' + ordenes.length + ' órdenes';

  if (visibles.length === 0) {
    listado.replaceChildren(crear('p', 'No hay órdenes con estos filtros.', 'empty'));
    return;
  }

  listado.replaceChildren(...visibles.map(crearOrden));
}

sedes.forEach(sede => filtroSede.add(new Option(sede.nombre, sede.id)));

try {
  const ordenes = await listarOrdenesCompra();
  filtroSede.addEventListener('change', () => renderizar(ordenes));
  filtroEstado.addEventListener('change', () => renderizar(ordenes));
  renderizar(ordenes);
} catch (error) {
  console.error('Error al cargar las órdenes de compra', error);
  conteo.textContent = error.message;
}