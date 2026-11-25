import { listarInventario, sedes } from './datos.js';
import { clasificar } from './estados.js';

const sede = document.querySelector('#sede');
const buscar = document.querySelector('#buscar');
const estado = document.querySelector('#estado');
const filas = document.querySelector('#filas');
const resumen = document.querySelector('#resumen');
const conteo = document.querySelector('#conteo');

const estados = {
  disponible: 'Disponible',
  bajo: 'Bajo mínimo',
  agotado: 'Agotado',
  ausente: 'Sin registro',
};
let inventario = [];

function normalizar(texto) {
  return texto.toLocaleLowerCase('es-CO').normalize('NFD').replace(/\p{Diacritic}/gu, '').trim();
}

function elemento(etiqueta, texto, clase) {
  const nodo = document.createElement(etiqueta);
  nodo.textContent = texto;
  if (clase) nodo.className = clase;
  return nodo;
}

function renderizarResumen() {
  const indicadores = [
    ['Referencias con registro', inventario.filter(p => p.estado !== 'ausente').length, 'disponible'],
    ['Bajo mínimo', inventario.filter(p => p.estado === 'bajo').length, 'bajo'],
    ['Agotadas', inventario.filter(p => p.estado === 'agotado').length, 'agotado'],
    ['Sin registro', inventario.filter(p => p.estado === 'ausente').length, 'ausente'],
  ];
  resumen.replaceChildren(...indicadores.map(([label, valor, clase]) => {
    const tarjeta = elemento('article', '', 'card');
    const titulo = elemento('span', label);
    titulo.prepend(elemento('i', '', 'dot ' + clase));
    tarjeta.append(titulo, elemento('strong', valor));
    return tarjeta;
  }));
}

function renderizarTabla() {
  const termino = normalizar(buscar.value);
  const visibles = inventario.filter(p =>
    (!estado.value || estado.value === p.estado) &&
    normalizar([p.nombre, p.sku, p.categoria].join(' ')).includes(termino)
  );
  conteo.textContent = visibles.length + ' de ' + inventario.length + ' referencias';

  if (!visibles.length) {
    const mensaje = elemento('td', 'No hay productos que coincidan con los filtros.', 'empty');
    mensaje.colSpan = 6;
    const fila = document.createElement('tr');
    fila.append(mensaje);
    filas.replaceChildren(fila);
    return;
  }

  filas.replaceChildren(...visibles.map(p => {
    const fila = document.createElement('tr');
    const producto = elemento('th', p.nombre);
    producto.scope = 'row';
    producto.append(elemento('small', p.sku));
    const estadoCelda = document.createElement('td');
    estadoCelda.append(elemento('span', estados[p.estado], 'badge ' + p.estado));
    fila.append(
      producto, elemento('td', p.categoria), elemento('td', p.almacen ?? '—'),
      elemento('td', p.existencia ?? '—', 'number'), elemento('td', p.minimo ?? '—', 'number'),
      estadoCelda,
    );
    return fila;
  }));
}

async function cargarSede() {
  const id = Number(sede.value);
  const registros = await listarInventario(id);
  if (Number(sede.value) !== id) return;
  inventario = registros.map(p => ({ ...p, estado: clasificar(p) }));
  renderizarResumen();
  renderizarTabla();
}

sede.append(...sedes.map(item => new Option(item.nombre, item.id)));
const sedeSolicitada = new URLSearchParams(window.location.search).get('sede');

if (sedes.some(item => String(item.id) === sedeSolicitada)) {
  sede.value = sedeSolicitada;
}
estado.append(...Object.entries(estados).map(([clave, nombre]) => new Option(nombre, clave)));
sede.addEventListener('change', cargarSede);
buscar.addEventListener('input', renderizarTabla);
estado.addEventListener('change', renderizarTabla);
document.querySelector('#filtros').addEventListener('reset', () => requestAnimationFrame(renderizarTabla));
document.querySelector('#filtros').addEventListener('submit', event => event.preventDefault());
await cargarSede();
