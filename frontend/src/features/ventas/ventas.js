import { sedes } from '../inventarios/datos.js';
import { listarPedidosVenta } from './datos.js';

const filtroSede = document.querySelector('#sede-venta');
const filtroEstado = document.querySelector('#estado-venta');
const soloSaldo = document.querySelector('#solo-saldo');
const filtros = document.querySelector('#filtros-ventas');
const listado = document.querySelector('#pedidos');
const conteo = document.querySelector('#conteo');

const sedesPorId = new Map(sedes.map(sede => [sede.id, sede.nombre]));

const moneda = new Intl.NumberFormat('es-CO', {
  style: 'currency',
  currency: 'COP',
  minimumFractionDigits: 0,
  maximumFractionDigits: 2,
});

const estados = {
  PENDIENTE: ['Pendiente', 'badge bajo'],
  CONFIRMADO: ['Confirmado', 'badge disponible'],
  COMPLETADO: ['Completado', 'badge disponible'],
  CANCELADO: ['Cancelado', 'badge ausente'],
  RECHAZADO: ['Rechazado', 'badge agotado'],
};

function crear(etiqueta, texto = '', clase = '') {
  const elemento = document.createElement(etiqueta);
  elemento.textContent = texto;
  if (clase) elemento.className = clase;
  return elemento;
}

function mostrarFecha(fecha) {
  return fecha.split('-').reverse().join('/');
}

function etiquetaEstado(estado) {
  const [texto, clase] = estados[estado] ?? [estado, 'badge ausente'];
  return crear('span', texto, clase);
}

function calcularImportes(pedido) {
  const total = pedido.total;

  const confirmado = pedido.pagos
    .filter(pago => pago.estado === 'CONFIRMADO')
    .reduce((suma, pago) => suma + pago.valor, 0);

  return {
    total,
    confirmado,
    saldo: pedido.estado === 'CANCELADO' ? null : total - confirmado,
  };
}

function crearTabla(nombre, columnas, registros) {
  const contenedor = crear('div', '', 'table-wrap');
  contenedor.tabIndex = 0;
  contenedor.setAttribute('role', 'region');
  contenedor.setAttribute('aria-label', nombre);

  const tabla = document.createElement('table');
  const cabecera = tabla.createTHead().insertRow();

  for (const [titulo, clase] of columnas) {
    const encabezado = crear('th', titulo, clase);
    encabezado.scope = 'col';
    cabecera.append(encabezado);
  }

  const cuerpo = tabla.createTBody();

  for (const registro of registros) {
    const fila = cuerpo.insertRow();

    registro.forEach((valor, indice) => {
      const celda = crear(indice === 0 ? 'th' : 'td', '', columnas[indice][1]);
      if (indice === 0) celda.scope = 'row';
      celda.append(valor);
      fila.append(celda);
    });
  }

  contenedor.append(tabla);
  return contenedor;
}

function crearPedido(pedido) {
  const detalle = crear('details', '', 'traslado');
  const encabezado = document.createElement('summary');
  const texto = document.createElement('span');
  const info = crear('span', '', 'traslado-estados');
  const sede = sedesPorId.get(pedido.sedeId) ?? 'Sede sin identificar';
  const { total, confirmado, saldo } = pedido.importes;

  texto.append(
    crear('strong', pedido.codigo + ' · ' + pedido.cliente),
    crear('small', sede + ' · ' + mostrarFecha(pedido.fecha)),
  );

  info.append(
    etiquetaEstado(pedido.estado),
    crear('span', 'Total ' + moneda.format(total), 'badge ausente'),
  );
  encabezado.append(texto, info);

  const textoSaldo = saldo === null ? 'No aplica' : moneda.format(saldo);
  const balance = crear(
    'p',
    'Pagos confirmados: ' + moneda.format(confirmado) +
      ' · Saldo por cobrar: ' + textoSaldo,
    'traslado-fechas',
  );

  const productos = crearTabla('Productos de ' + pedido.codigo, [
    ['Producto'], ['Cantidad', 'number'],
    ['Precio unitario', 'number'], ['Subtotal', 'number'],
  ], pedido.lineas.map(linea => {
    const producto = crear('span', linea.producto);
    producto.append(crear('small', linea.sku));

    return [
      producto,
      String(linea.cantidad),
      moneda.format(linea.precioUnitario),
      moneda.format(linea.cantidad * linea.precioUnitario),
    ];
  }));

  const pagos = pedido.pagos.length
    ? crearTabla('Pagos de ' + pedido.codigo, [
      ['Referencia'], ['Fecha'], ['Medio'], ['Valor', 'number'], ['Estado'],
    ], pedido.pagos.map(pago => [
      pago.referencia,
      mostrarFecha(pago.fecha),
      pago.medio,
      moneda.format(pago.valor),
      etiquetaEstado(pago.estado),
    ]))
    : crear('p', 'Este pedido aún no tiene pagos registrados.', 'traslado-fechas');

  detalle.append(
    encabezado,
    balance,
    productos,
    crear('h3', 'Historial de pagos', 'titulo-pagos'),
    pagos,
  );

  return detalle;
}

function renderizar(pedidos) {
  const visibles = pedidos.filter(pedido =>
    (!filtroSede.value || pedido.sedeId === Number(filtroSede.value)) &&
    (!filtroEstado.value || pedido.estado === filtroEstado.value) &&
    (!soloSaldo.checked || pedido.importes.saldo > 0),
  );

  conteo.textContent = visibles.length + ' de ' + pedidos.length + ' pedidos';

  listado.replaceChildren(...(
    visibles.length
      ? visibles.map(crearPedido)
      : [crear('p', 'No hay pedidos con estos filtros.', 'empty')]
  ));
}

for (const sede of sedes) {
  if (sede.tipo !== 'DISTRIBUCION') {
    filtroSede.add(new Option(sede.nombre, sede.id));
  }
}

try {
  const pedidos = (await listarPedidosVenta()).map(pedido => ({
    ...pedido,
    importes: calcularImportes(pedido),
  }));

  filtros.addEventListener('change', () => renderizar(pedidos));
  filtros.addEventListener('reset', () => {
    requestAnimationFrame(() => renderizar(pedidos));
  });
  filtros.addEventListener('submit', evento => evento.preventDefault());

  renderizar(pedidos);
} catch (error) {
  console.error('Error al cargar los pedidos', error);
  conteo.textContent = error.message;
}