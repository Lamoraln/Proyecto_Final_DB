from datetime import datetime
from pathlib import Path
from shutil import copy2
from textwrap import dedent


raiz = Path(__file__).resolve().parent
frontend = raiz / "frontend"
archivos = {}


def guardar(ruta, contenido):
    archivos[ruta] = dedent(contenido).strip() + "\n"


guardar("src/app/sesion.js", """
export const cuentasDemo = [
  { id: 'administrador', nombre: 'Administrador', rol: 'ADMINISTRADOR', sedes: null },
  { id: 'gerencia', nombre: 'Gerencia', rol: 'GERENCIA', sedes: null },
  { id: 'inventario', nombre: 'Responsable de inventario', rol: 'RESP_INVENTARIO', sedes: [1, 4] },
  { id: 'compras', nombre: 'Responsable de compras', rol: 'RESP_COMPRAS', sedes: [1, 2] },
  { id: 'vendedor', nombre: 'Vendedor · Bogotá Sur', rol: 'VENDEDOR', sedes: [2] },
  { id: 'auditor', nombre: 'Auditor', rol: 'AUDITOR', sedes: null },
];

const claveSesion = 'distribured.cuenta-demo';

const pantallasPorRol = {
  ADMINISTRADOR: [
    'index.html', 'resumen.html', 'transferencias.html', 'compras.html',
    'ventas.html', 'catalogo.html', 'devoluciones.html', 'identidad.html',
  ],
  GERENCIA: ['resumen.html', 'index.html'],
  RESP_INVENTARIO: ['index.html', 'transferencias.html'],
  RESP_COMPRAS: ['compras.html'],
  VENDEDOR: ['ventas.html'],
  AUDITOR: ['resumen.html'],
};

export function sesionActual() {
  const id = sessionStorage.getItem(claveSesion);
  return cuentasDemo.find(cuenta => cuenta.id === id) ?? null;
}

export function iniciarSesionDemo(id) {
  const cuenta = cuentasDemo.find(item => item.id === id);
  if (!cuenta) return null;

  sessionStorage.setItem(claveSesion, cuenta.id);
  return cuenta;
}

export function cerrarSesion() {
  sessionStorage.removeItem(claveSesion);
}

export function permitePantalla(cuenta, pagina) {
  return pantallasPorRol[cuenta?.rol]?.includes(pagina) ?? false;
}

export function paginaInicio(cuenta) {
  return pantallasPorRol[cuenta?.rol]?.[0] ?? 'login.html';
}

export function permiteSede(cuenta, sedeId) {
  return Boolean(cuenta && (
    cuenta.sedes === null || cuenta.sedes.includes(Number(sedeId))
  ));
}
""")

guardar("src/app/login.js", """
import { cuentasDemo, iniciarSesionDemo, paginaInicio } from './sesion.js';

const formulario = document.querySelector('#login-form');
const selector = document.querySelector('#cuenta-demo');
const mensaje = document.querySelector('#login-mensaje');

for (const cuenta of cuentasDemo) {
  selector.add(new Option(cuenta.nombre, cuenta.id));
}

formulario.addEventListener('submit', evento => {
  evento.preventDefault();

  try {
    const cuenta = iniciarSesionDemo(selector.value);

    if (!cuenta) {
      mensaje.textContent = 'Selecciona una cuenta de demostración.';
      return;
    }

    window.location.replace('./' + paginaInicio(cuenta));
  } catch (error) {
    console.error('No se pudo iniciar la sesión', error);
    mensaje.textContent = 'El navegador no pudo guardar la sesión de demostración.';
  }
});
""")

guardar("src/app/navegacion.js", """
import { cerrarSesion, paginaInicio, permitePantalla, sesionActual } from './sesion.js';

const secciones = {
  'index.html': {
    titulo: 'Inventario', icono: '▦',
    cargar: () => import('../features/inventarios/inventario.js'),
  },
  'resumen.html': {
    titulo: 'Resumen multisede', icono: '▤',
    cargar: () => Promise.all([
      import('../features/reportes/resumen.js'),
      import('../features/reportes/consolidado.js'),
    ]),
  },
  'transferencias.html': {
    titulo: 'Transferencias', icono: '⇄',
    cargar: () => import('../features/transferencias/transferencias.js'),
  },
  'compras.html': {
    titulo: 'Compras', icono: '▣',
    cargar: () => import('../features/compras/compras.js'),
  },
  'ventas.html': {
    titulo: 'Ventas y pagos', icono: '▥',
    cargar: () => import('../features/ventas/ventas.js'),
  },
  'catalogo.html': {
    titulo: 'Catálogo y terceros', icono: '▧',
    cargar: () => import('../features/catalogo/catalogo.js'),
  },
  'devoluciones.html': {
    titulo: 'Devoluciones', icono: '↶',
    cargar: () => import('../features/ventas/devoluciones.js'),
  },
  'identidad.html': {
    titulo: 'Identidad y accesos', icono: '◉',
    cargar: () => import('../features/identidad/identidad.js'),
  },
};

const pagina = location.pathname.split('/').pop() || 'index.html';
const contenido = document.querySelector('main');
const pantallaPequena = matchMedia('(max-width: 850px)');

function mostrarMensaje(titulo, texto, destino, etiqueta) {
  const panel = document.createElement('section');
  panel.className = 'panel acceso-denegado';

  const encabezado = document.createElement('h1');
  encabezado.textContent = titulo;

  const mensaje = document.createElement('p');
  mensaje.textContent = texto;

  const enlace = document.createElement('a');
  enlace.href = './' + destino;
  enlace.textContent = etiqueta;

  panel.append(encabezado, mensaje, enlace);
  contenido.replaceChildren(panel);
  contenido.hidden = false;
}

function montarMenu(cuenta) {
  const barra = document.querySelector('#barra-lateral');
  const cabecera = document.querySelector('.top');
  const workspace = document.querySelector('.workspace');

  barra.innerHTML = `
    <a class="brand"><span class="logo" aria-hidden="true">◆</span> DistribuRed</a>
    <nav aria-label="Navegación principal"></nav>
    <div class="sesion-menu">
      <small>Cuenta de demostración</small>
      <strong class="perfil-activo"></strong>
      <button type="button" class="cerrar-sesion">Cerrar sesión</button>
    </div>
  `;

  barra.querySelector('.brand').href = './' + paginaInicio(cuenta);
  barra.querySelector('.perfil-activo').textContent = cuenta.nombre;
  barra.querySelector('.cerrar-sesion').addEventListener('click', () => {
    cerrarSesion();
    location.replace('./login.html');
  });

  const menu = barra.querySelector('nav');

  for (const [archivo, seccion] of Object.entries(secciones)) {
    if (!permitePantalla(cuenta, archivo)) continue;

    const enlace = document.createElement('a');
    enlace.href = './' + archivo;

    const icono = document.createElement('span');
    icono.setAttribute('aria-hidden', 'true');
    icono.textContent = seccion.icono;
    enlace.append(icono, seccion.titulo);

    if (archivo === pagina) enlace.setAttribute('aria-current', 'page');
    menu.append(enlace);
  }

  const boton = document.createElement('button');
  boton.type = 'button';
  boton.className = 'boton-menu';
  boton.textContent = '☰ Menú';
  boton.setAttribute('aria-controls', barra.id);
  cabecera.prepend(boton);

  function abrirMenu(abierto) {
    barra.hidden = !abierto;
    document.body.classList.toggle('menu-abierto', abierto);
    boton.setAttribute('aria-expanded', String(abierto));
  }

  function ajustarPantalla() {
    const devolverFoco = barra.contains(document.activeElement);

    if (pantallaPequena.matches) {
      cabecera.after(barra);
    } else {
      workspace.before(barra);
    }

    abrirMenu(!pantallaPequena.matches);
    if (devolverFoco) boton.focus();
  }

  boton.addEventListener('click', () => abrirMenu(barra.hidden));
  pantallaPequena.addEventListener('change', ajustarPantalla);
  ajustarPantalla();
}

async function iniciarPagina() {
  const cuenta = sesionActual();

  if (!cuenta) {
    location.replace('./login.html');
    return;
  }

  montarMenu(cuenta);

  if (!permitePantalla(cuenta, pagina)) {
    mostrarMensaje(
      'Acceso denegado',
      'Tu perfil no tiene permiso para abrir esta pantalla.',
      paginaInicio(cuenta),
      'Volver a mi inicio',
    );
    return;
  }

  await secciones[pagina].cargar();
  contenido.hidden = false;
}

// Revalida el perfil si el navegador restaura una página al pulsar Atrás.
addEventListener('pageshow', evento => {
  if (evento.persisted) location.reload();
});

iniciarPagina().catch(error => {
  console.error('No se pudo cargar ' + pagina, error);
  mostrarMensaje(
    'No se pudo cargar la pantalla',
    'Revisa el primer error de la consola del navegador para identificar el archivo afectado.',
    'login.html',
    'Volver al acceso',
  );
});
""")

guardar("src/app/navegacion.css", """
body.layout-navegacion {
  display: grid;
  grid-template-columns: minmax(0, 1fr);
}

.layout-navegacion > .workspace {
  grid-column: 1;
  grid-row: 1;
  min-width: 0;
}

.layout-navegacion .sidebar[hidden],
.layout-navegacion main[hidden] {
  display: none;
}

.layout-navegacion .table-wrap {
  max-width: 100%;
  overflow-x: auto;
}

.layout-navegacion .top {
  display: flex;
  align-items: center;
  justify-content: flex-start;
  gap: 12px;
}

.layout-navegacion .top > span:not(.avatar) {
  min-width: 0;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.layout-navegacion .top .avatar {
  flex: 0 0 auto;
  margin-inline-start: auto;
}

.layout-navegacion .boton-menu {
  flex: 0 0 auto;
  min-height: 36px;
  padding: 5px 10px;
}

.layout-navegacion .sidebar nav {
  display: grid;
  gap: 5px;
}

.layout-navegacion .sidebar nav a {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 10px 13px;
  border-radius: 8px;
  color: #c1d5d6;
  text-decoration: none;
  font-weight: 650;
}

.layout-navegacion .sidebar nav a:hover,
.layout-navegacion .sidebar nav a[aria-current="page"] {
  background: #22464a;
  color: #aaf6e3;
}

@media (width > 850px) {
  body.layout-navegacion.menu-abierto {
    grid-template-columns: 218px minmax(0, 1fr);
  }

  .layout-navegacion > .sidebar {
    grid-column: 1;
    grid-row: 1;
    position: sticky;
    top: 0;
    align-self: start;
    height: 100vh;
    height: 100dvh;
    overflow-y: auto;
  }

  .layout-navegacion.menu-abierto > .workspace {
    grid-column: 2;
  }
}

@media (width <= 850px) {
  .layout-navegacion .sidebar {
    position: static;
    flex-direction: column;
    align-items: stretch;
    gap: 12px;
    height: auto;
    padding: 12px 16px;
  }
}
""")

guardar("src/app/acceso.css", """
body.pagina-login {
  display: grid;
  grid-template-columns: minmax(0, 1fr);
  place-items: center;
  padding: 16px;
}

.login-panel {
  width: min(100%, 420px);
  margin: 0;
  padding: 28px;
  background: #fff;
  border: 1px solid var(--line);
  border-radius: 14px;
}

.login-panel h1 {
  margin-top: 14px;
}

.login-panel p {
  margin-top: 8px;
  color: var(--muted);
}

.login-panel form,
.sesion-menu {
  display: grid;
  gap: 8px;
}

.login-panel form {
  margin-top: 22px;
}

.login-panel button {
  background: var(--accent);
  border-color: var(--accent);
  color: #fff;
}

.login-panel #login-mensaje {
  color: #962842;
}

#login-mensaje:empty {
  display: none;
}

.sesion-menu {
  margin-top: auto;
}

.sesion-menu small {
  color: #c1d5d6;
}

.acceso-denegado {
  padding: 24px;
}

.acceso-denegado p {
  margin: 10px 0;
}
""")

guardar("login.html", """
<!doctype html>
<html lang="es-CO">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Acceso de demostración | DistribuRed</title>
  <link rel="stylesheet" href="./src/app/styles.css">
  <link rel="stylesheet" href="./src/app/acceso.css">
  <script type="module" src="./src/app/login.js"></script>
</head>
<body class="pagina-login">
  <main class="login-panel">
    <span class="logo" aria-hidden="true">◆</span>
    <h1>DistribuRed</h1>
    <p>Elige una cuenta de demostración para entrar.</p>
    <form id="login-form">
      <label for="cuenta-demo">Perfil</label>
      <select id="cuenta-demo" required>
        <option value="">Selecciona un perfil</option>
      </select>
      <button type="submit">Entrar</button>
      <p id="login-mensaje" role="alert"></p>
    </form>
  </main>
</body>
</html>
""")


# Cada pantalla operativa arranca exclusivamente desde navegacion.js.
def pagina(archivo, titulo, descripcion, contenido):
    guardar(archivo, f"""
<!doctype html>
<html lang="es-CO">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>{titulo} | DistribuRed</title>
  <link rel="stylesheet" href="./src/app/styles.css">
  <link rel="stylesheet" href="./src/app/navegacion.css">
  <link rel="stylesheet" href="./src/app/acceso.css">
  <script type="module" src="./src/app/navegacion.js"></script>
</head>
<body class="layout-navegacion">
  <aside class="sidebar" id="barra-lateral" hidden></aside>
  <div class="workspace">
    <header class="top">
      <span>Operaciones <b>/</b> {titulo}</span>
      <span class="avatar" aria-label="DistribuRed">DR</span>
    </header>
    <main hidden>
      <section class="hero">
        <div><h1>{titulo}</h1><p>{descripcion}</p></div>
        {"<label>Sede operativa<select id='sede'></select></label>" if archivo == "index.html" else ""}
      </section>
      {dedent(contenido).strip()}
    </main>
    <noscript><p>Activa JavaScript para usar DistribuRed.</p></noscript>
  </div>
</body>
</html>
""")


pagina("index.html", "Inventario por sede",
       "Consulta existencias y detecta productos que necesitan reposición.", """
<section class="cards" id="resumen" aria-label="Resumen de inventario"></section>
<section class="panel" aria-labelledby="titulo-tabla">
  <div class="panel-title"><h2 id="titulo-tabla">Productos</h2><span id="conteo" role="status"></span></div>
  <form class="filters" id="filtros">
    <label class="search">Buscar producto<input id="buscar" type="search" placeholder="Nombre, SKU o categoría"></label>
    <label>Estado<select id="estado"><option value="">Todos los estados</option></select></label>
    <button type="reset">Limpiar filtros</button>
  </form>
  <div class="table-wrap" role="region" aria-labelledby="titulo-tabla" tabindex="0">
    <table>
      <thead><tr>
        <th scope="col">Producto</th><th scope="col">Categoría</th><th scope="col">Almacén</th>
        <th scope="col" class="number">Existencia</th><th scope="col" class="number">Mínimo</th>
        <th scope="col">Estado</th>
      </tr></thead>
      <tbody id="filas"></tbody>
    </table>
  </div>
</section>
""")

pagina("resumen.html", "Resumen multisede",
       "Identifica dónde hay agotados y qué sedes necesitan reposición.", """
<section class="cards" id="indicadores" aria-label="Indicadores multisede"></section>
<section class="panel" aria-labelledby="titulo-sedes">
  <div class="panel-title"><h2 id="titulo-sedes">Inventario por sede</h2><span id="estado-resumen" role="status">Cargando inventario…</span></div>
  <div class="table-wrap" role="region" aria-labelledby="titulo-sedes" tabindex="0">
    <table>
      <thead><tr>
        <th scope="col">Sede</th><th scope="col" class="number">Unidades</th>
        <th scope="col" class="number">Bajo mínimo</th>
        <th scope="col" class="number">Agotadas</th>
        <th scope="col" class="number">Sin registro</th><th scope="col">Detalle</th>
      </tr></thead>
      <tbody id="filas-sedes"></tbody>
    </table>
  </div>
</section>
<section class="panel" id="consolidado-corporativo" aria-labelledby="titulo-consolidado">
  <div class="panel-title"><h2 id="titulo-consolidado">Consolidado operativo por sede</h2></div>
  <div id="tabla-consolidado"><p class="empty" role="status">Cargando consolidado…</p></div>
</section>
""")

pagina("transferencias.html", "Transferencias entre almacenes",
       "Consulta los traslados y verifica las cantidades recibidas.", """
<section class="panel transferencias" aria-labelledby="titulo-traslados">
  <div class="panel-title"><h2 id="titulo-traslados">Traslados</h2><span id="conteo" role="status"></span></div>
  <div class="filters">
    <label>Estado
      <select id="estado">
        <option value="">Todos los estados</option>
        <option value="EN_TRANSITO">En tránsito</option>
        <option value="RECIBIDA">Recibida</option>
      </select>
    </label>
    <label>Sede de destino<select id="destino"><option value="">Todas las sedes</option></select></label>
  </div>
  <div id="traslados"></div>
</section>
""")

pagina("compras.html", "Compras y recepciones",
       "Consulta qué llegó a cada almacén y qué sigue pendiente.", """
<section class="panel transferencias" aria-labelledby="titulo-ordenes">
  <div class="panel-title"><h2 id="titulo-ordenes">Órdenes de compra</h2><span id="conteo" role="status"></span></div>
  <div class="filters">
    <label>Sede de destino<select id="sede-compra"><option value="">Todas las sedes</option></select></label>
    <label>Estado
      <select id="estado-compra">
        <option value="">Todos los estados</option>
        <option value="PENDIENTE">Pendiente</option>
        <option value="PARCIAL">Parcial</option>
        <option value="RECIBIDA">Recibida</option>
        <option value="CANCELADA">Cancelada</option>
      </select>
    </label>
  </div>
  <div id="ordenes"></div>
</section>
""")

pagina("ventas.html", "Ventas y pagos",
       "Consulta los pedidos, los abonos confirmados y los saldos por cobrar.", """
<section class="panel transferencias" aria-labelledby="titulo-pedidos">
  <div class="panel-title"><h2 id="titulo-pedidos">Pedidos de venta</h2><span id="conteo" role="status"></span></div>
  <form class="filters" id="filtros-ventas">
    <label>Sede comercial<select id="sede-venta"><option value="">Todas las sedes</option></select></label>
    <label>Estado del pedido
      <select id="estado-venta">
        <option value="">Todos los estados</option>
        <option value="PENDIENTE">Pendiente</option>
        <option value="CONFIRMADO">Confirmado</option>
        <option value="COMPLETADO">Completado</option>
        <option value="CANCELADO">Cancelado</option>
      </select>
    </label>
    <label><span><input type="checkbox" id="solo-saldo"> Solo con saldo pendiente</span></label>
    <button type="reset">Limpiar filtros</button>
  </form>
  <div id="pedidos"></div>
</section>
""")

directorio = '<section class="panel directorio" id="directorio" aria-label="Consulta de registros"></section>'
pagina("catalogo.html", "Catálogo y terceros", "Consulta productos, terceros, sedes y almacenes.", directorio)
pagina("devoluciones.html", "Devoluciones", "Consulta las devoluciones y el saldo devolvible por línea.", directorio)
pagina("identidad.html", "Identidad y accesos", "Consulta empleados, cuentas y eventos de demostración.", directorio)


guardar("src/features/inventarios/datos.js", """
import { permiteSede, sesionActual } from '../../app/sesion.js';

export const todasLasSedes = [
  { id: 1, nombre: 'Bogotá Norte', almacen: 'Almacén Norte' },
  { id: 2, nombre: 'Bogotá Sur', almacen: 'Almacén Sur' },
  { id: 3, nombre: 'Medellín', almacen: 'Almacén Medellín' },
  { id: 4, nombre: 'Centro de distribución', almacen: 'Bodega central' },
];

export const sedes = todasLasSedes.filter(sede => permiteSede(sesionActual(), sede.id));

const productos = [
  { sku: 'EM-104', nombre: 'Caja corrugada mediana', categoria: 'Empaques', minimo: 40, cantidades: [126, 58, 92, 380] },
  { sku: 'EM-212', nombre: 'Cinta de embalaje', categoria: 'Empaques', minimo: 25, cantidades: [11, 32, 48, 180] },
  { sku: 'OF-086', nombre: 'Papel carta · resma', categoria: 'Papelería', minimo: 30, cantidades: [0, 70, 8, 140] },
  { sku: 'OF-119', nombre: 'Etiquetas adhesivas', categoria: 'Papelería', minimo: 20, cantidades: [64, null, 19, 116] },
  { sku: 'SE-044', nombre: 'Guantes de seguridad', categoria: 'Protección', minimo: 24, cantidades: [18, 0, 36, 82] },
  { sku: 'SE-046', nombre: 'Gafas de protección', categoria: 'Protección', minimo: 15, cantidades: [null, 23, 17, 70] },
  { sku: 'EM-305', nombre: 'Papel kraft', categoria: 'Empaques', minimo: 15, cantidades: [42, 24, null, 92] },
  { sku: 'AL-021', nombre: 'Alcohol desinfectante', categoria: 'Aseo', minimo: 12, cantidades: [21, 17, 0, 56] },
];

export async function listarInventario(sedeId) {
  if (!permiteSede(sesionActual(), sedeId)) return [];

  const indice = todasLasSedes.findIndex(sede => sede.id === Number(sedeId));
  if (indice === -1) return [];

  return productos.map(({ sku, nombre, categoria, minimo, cantidades }) => {
    const existencia = cantidades[indice];

    return {
      sku, nombre, categoria, existencia,
      almacen: existencia === null ? null : todasLasSedes[indice].almacen,
      minimo: existencia === null ? null : minimo,
    };
  });
}
""")

guardar("src/features/inventarios/estados.js", """
export function clasificar({ existencia, minimo }) {
  if (existencia === null) return 'ausente';
  if (existencia === 0) return 'agotado';
  if (existencia < minimo) return 'bajo';
  return 'disponible';
}
""")

guardar("src/features/compras/datos.js", """
import { permiteSede, sesionActual } from '../../app/sesion.js';

const ordenes = [
  {
    codigo: 'OC-001', proveedor: 'Suministros Andinos', sedeId: 2,
    fechaEstimada: '2026-11-28', estado: 'PENDIENTE',
    lineas: [{ sku: 'SE-044', producto: 'Guantes de seguridad', solicitada: 30 }],
    recepciones: [],
  },
  {
    codigo: 'OC-002', proveedor: 'Empaques del Centro', sedeId: 1,
    fechaEstimada: '2026-11-26', estado: 'PARCIAL',
    lineas: [
      { sku: 'EM-104', producto: 'Caja corrugada mediana', solicitada: 20 },
      { sku: 'EM-212', producto: 'Cinta de embalaje', solicitada: 10 },
    ],
    recepciones: [
      { codigo: 'RC-001', lineas: [{ sku: 'EM-104', cantidad: 6 }, { sku: 'EM-212', cantidad: 10 }] },
      { codigo: 'RC-002', lineas: [{ sku: 'EM-104', cantidad: 8 }] },
    ],
  },
  {
    codigo: 'OC-003', proveedor: 'Papelería Industrial', sedeId: 3,
    fechaEstimada: '2026-11-23', estado: 'RECIBIDA',
    lineas: [{ sku: 'OF-119', producto: 'Etiquetas adhesivas', solicitada: 40 }],
    recepciones: [{ codigo: 'RC-003', lineas: [{ sku: 'OF-119', cantidad: 40 }] }],
  },
];

export async function listarOrdenesCompra() {
  const cuenta = sesionActual();
  return ordenes.filter(orden => permiteSede(cuenta, orden.sedeId));
}
""")

guardar("src/features/ventas/datos.js", """
import { permiteSede, sesionActual } from '../../app/sesion.js';

export const idsSedesComerciales = [1, 2, 3];

const pedidos = [
  {
    codigo: 'PV-001', sedeId: 1, cliente: 'Comercial Andina',
    fecha: '2026-11-20', estado: 'CONFIRMADO',
    lineas: [
      { sku: 'EM-104', producto: 'Caja corrugada mediana', cantidad: 10, precioUnitario: 12000 },
      { sku: 'EM-212', producto: 'Cinta de embalaje', cantidad: 2, precioUnitario: 15000 },
    ],
    pagos: [
      { referencia: 'PG-001', fecha: '2026-11-20', medio: 'Transferencia', valor: 40000, estado: 'CONFIRMADO' },
      { referencia: 'PG-002', fecha: '2026-11-21', medio: 'Efectivo', valor: 30000, estado: 'CONFIRMADO' },
      { referencia: 'PG-003', fecha: '2026-11-24', medio: 'Transferencia', valor: 80000, estado: 'PENDIENTE' },
    ],
  },
  {
    codigo: 'PV-002', sedeId: 2, cliente: 'Papelería Horizonte',
    fecha: '2026-11-21', estado: 'COMPLETADO',
    lineas: [{ sku: 'OF-119', producto: 'Etiquetas adhesivas', cantidad: 4, precioUnitario: 10000 }],
    pagos: [
      { referencia: 'PG-004', fecha: '2026-11-21', medio: 'Tarjeta', valor: 40000, estado: 'CONFIRMADO' },
    ],
  },
  {
    codigo: 'PV-003', sedeId: 3, cliente: 'Suministros El Roble',
    fecha: '2026-11-23', estado: 'PENDIENTE',
    lineas: [{ sku: 'SE-044', producto: 'Guantes de seguridad', cantidad: 5, precioUnitario: 16000 }],
    pagos: [],
  },
  {
    codigo: 'PV-004', sedeId: 2, cliente: 'Empaques del Valle',
    fecha: '2026-11-24', estado: 'CANCELADO',
    lineas: [{ sku: 'EM-305', producto: 'Papel kraft', cantidad: 3, precioUnitario: 9000 }],
    pagos: [
      { referencia: 'PG-005', fecha: '2026-11-24', medio: 'Tarjeta', valor: 27000, estado: 'RECHAZADO' },
    ],
  },
];

export async function listarPedidosVenta() {
  const cuenta = sesionActual();
  return pedidos.filter(pedido => permiteSede(cuenta, pedido.sedeId));
}
""")

guardar("src/features/transferencias/datos.js", """
import { permiteSede, sesionActual } from '../../app/sesion.js';

const transferencias = [
  {
    codigo: 'TR-001', origen: 4, destino: 2, estado: 'EN_TRANSITO',
    despacho: '2026-11-24', recepcion: null,
    productos: [
      { sku: 'SE-044', nombre: 'Guantes de seguridad', enviada: 30, recibida: null },
      { sku: 'EM-212', nombre: 'Cinta de embalaje', enviada: 15, recibida: null },
    ],
  },
  {
    codigo: 'TR-002', origen: 4, destino: 1, estado: 'RECIBIDA',
    despacho: '2026-11-20', recepcion: '2026-11-21',
    productos: [{ sku: 'OF-119', nombre: 'Etiquetas adhesivas', enviada: 40, recibida: 40 }],
  },
  {
    codigo: 'TR-003', origen: 1, destino: 3, estado: 'RECIBIDA',
    despacho: '2026-11-21', recepcion: '2026-11-23',
    productos: [
      { sku: 'EM-104', nombre: 'Caja corrugada mediana', enviada: 20, recibida: 17 },
      { sku: 'SE-046', nombre: 'Gafas de protección', enviada: 10, recibida: 10 },
    ],
  },
];

export async function listarTransferencias() {
  const cuenta = sesionActual();

  return transferencias.filter(traslado =>
    permiteSede(cuenta, traslado.origen) || permiteSede(cuenta, traslado.destino),
  );
}
""")

guardar("src/features/transferencias/transferencias.js", """
import { todasLasSedes } from '../inventarios/datos.js';
import { listarTransferencias } from './datos.js';

const filtroEstado = document.querySelector('#estado');
const filtroDestino = document.querySelector('#destino');
const listado = document.querySelector('#traslados');
const conteo = document.querySelector('#conteo');
const sedesPorId = new Map(todasLasSedes.map(sede => [sede.id, sede]));

const estados = {
  EN_TRANSITO: ['En tránsito', 'badge bajo'],
  RECIBIDA: ['Recibida', 'badge disponible'],
};

function crear(etiqueta, texto = '', clase = '') {
  const nodo = document.createElement(etiqueta);
  nodo.textContent = texto;
  if (clase) nodo.className = clase;
  return nodo;
}

function mostrarFecha(fecha) {
  return fecha ? fecha.split('-').reverse().join('/') : 'Pendiente';
}

function nombreAlmacen(id) {
  const sede = sedesPorId.get(id);
  return sede ? sede.nombre + ' · ' + sede.almacen : 'Almacén sin identificar';
}

function crearTabla(traslado) {
  const contenedor = crear('div', '', 'table-wrap');
  contenedor.tabIndex = 0;
  contenedor.setAttribute('role', 'region');
  contenedor.setAttribute('aria-label', 'Productos de ' + traslado.codigo);

  const tabla = document.createElement('table');
  const encabezado = tabla.createTHead().insertRow();

  for (const titulo of ['Producto', 'Enviada', 'Recibida', 'Diferencia']) {
    const columna = crear('th', titulo);
    columna.scope = 'col';
    encabezado.append(columna);
  }

  const cuerpo = tabla.createTBody();

  for (const producto of traslado.productos) {
    const diferencia = producto.recibida === null
      ? '—'
      : producto.recibida - producto.enviada;

    cuerpo.insertRow().append(
      crear('td', producto.nombre + ' · ' + producto.sku),
      crear('td', producto.enviada, 'number'),
      crear('td', producto.recibida ?? 'Pendiente', 'number'),
      crear('td', diferencia, 'number'),
    );
  }

  contenedor.append(tabla);
  return contenedor;
}

function crearTraslado(traslado) {
  const detalle = crear('details', '', 'traslado');
  const cabecera = crear('summary');
  const texto = crear('span');
  const indicadores = crear('span', '', 'traslado-estados');
  const [estado, clase] = estados[traslado.estado] ?? [traslado.estado, 'badge ausente'];

  texto.append(
    crear('strong', traslado.codigo),
    crear('small', nombreAlmacen(traslado.origen) + ' → ' + nombreAlmacen(traslado.destino)),
  );

  indicadores.append(crear('span', estado, clase));

  if (traslado.productos.some(p => p.recibida !== null && p.recibida !== p.enviada)) {
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
  listado.replaceChildren(...(
    visibles.length ? visibles.map(crearTraslado)
      : [crear('p', 'No hay traslados con estos filtros.', 'empty')]
  ));
}

const transferencias = await listarTransferencias();
const destinos = new Set(transferencias.map(traslado => traslado.destino));

for (const sede of todasLasSedes) {
  if (destinos.has(sede.id)) filtroDestino.add(new Option(sede.nombre, sede.id));
}

filtroDestino.addEventListener('change', () => renderizar(transferencias));
filtroEstado.addEventListener('change', () => renderizar(transferencias));
renderizar(transferencias);
""")


# Si falta un módulo anterior, informa su ruta antes de reemplazar archivos.
requeridos = [
    "src/app/styles.css",
    "src/features/inventarios/inventario.js",
    "src/features/reportes/resumen.js",
    "src/features/reportes/consolidado.js",
    "src/features/compras/compras.js",
    "src/features/ventas/ventas.js",
    "src/features/ventas/devoluciones.js",
    "src/features/catalogo/catalogo.js",
    "src/features/identidad/identidad.js",
    "src/shared/directorio.js",
]

faltantes = [ruta for ruta in requeridos if not (frontend / ruta).is_file()]
if faltantes:
    raise SystemExit(
        "No se reemplazó ningún archivo. Faltan módulos anteriores o el script "
        "está en la carpeta equivocada:\n" + "\n".join(faltantes)
    )

respaldo = raiz / ("respaldo-frontend-" + datetime.now().strftime("%Y%m%d-%H%M%S-%f"))

for ruta in archivos:
    original = frontend / ruta
    if original.is_file():
        copia = respaldo / ruta
        copia.parent.mkdir(parents=True, exist_ok=True)
        copy2(original, copia)

for ruta, contenido in archivos.items():
    destino = frontend / ruta
    destino.parent.mkdir(parents=True, exist_ok=True)
    destino.write_text(contenido, encoding="utf-8")
    print("Actualizado:", ruta)

print("\nRespaldo:", respaldo)
print("Abre http://localhost:8000/login.html")