import {
  cerrarSesion,
  paginaInicio,
  permitePantalla,
  sesionActual,
} from './sesion.js';

const secciones = {
  'index.html': ['Inventario', '▦', () => import('../features/inventarios/inventario.js')],
  'resumen.html': ['Resumen multisede', '▤', () => Promise.all([
    import('../features/reportes/resumen.js'),
    import('../features/reportes/consolidado.js'),
    import('../features/reportes/vistas.js'),
  ])],
  'transferencias.html': ['Transferencias', '⇄', () => import('../features/transferencias/transferencias.js')],
  'compras.html': ['Compras', '▣', () => import('../features/compras/compras.js')],
  'ventas.html': ['Ventas y pagos', '▥', () => import('../features/ventas/ventas.js')],
  'catalogo.html': ['Catálogo y terceros', '▧', () => import('../features/catalogo/catalogo.js')],
  'devoluciones.html': ['Devoluciones', '↶', () => import('../features/ventas/devoluciones.js')],
  'identidad.html': ['Identidad y accesos', '◉', () => import('../features/identidad/identidad.js')],
};

const pagina = location.pathname.split('/').pop() || 'index.html';
const contenido = document.querySelector('main');
const barra = document.querySelector('#barra-lateral');
const cabecera = document.querySelector('.top');
const workspace = document.querySelector('.workspace');
const movil = matchMedia('(max-width: 850px)');

function mostrarMensaje(titulo, texto, destino) {
  const panel = document.createElement('section');
  panel.className = 'panel acceso-denegado';

  const encabezado = document.createElement('h1');
  encabezado.textContent = titulo;

  const mensaje = document.createElement('p');
  mensaje.textContent = texto;

  const enlace = document.createElement('a');
  enlace.href = './' + destino;
  enlace.textContent = destino === 'login.html' ? 'Ir al acceso' : 'Volver a mi inicio';

  panel.append(encabezado, mensaje, enlace);
  contenido.replaceChildren(panel);
  contenido.hidden = false;
}

function montarMenu(cuenta) {
  barra.innerHTML = `
    <a class="brand"><span class="logo" aria-hidden="true">◆</span> DistribuRed</a>
    <nav aria-label="Navegación principal"></nav>
    <div class="sesion-menu">
      <small>Sesión activa</small>
      <strong class="perfil-activo"></strong>
      <button class="cerrar-sesion" type="button">Cerrar sesión</button>
    </div>
  `;

  barra.querySelector('.brand').href = './' + paginaInicio(cuenta);
  barra.querySelector('.perfil-activo').textContent = cuenta.nombre;
  barra.querySelector('.cerrar-sesion').addEventListener('click', () => {
    cerrarSesion();
    location.replace('./login.html');
  });

  const menu = barra.querySelector('nav');

  for (const [archivo, [titulo, simbolo]] of Object.entries(secciones)) {
    if (!permitePantalla(cuenta, archivo)) continue;

    const enlace = document.createElement('a');
    enlace.href = './' + archivo;

    const icono = document.createElement('span');
    icono.setAttribute('aria-hidden', 'true');
    icono.textContent = simbolo;
    enlace.append(icono, titulo);

    if (archivo === pagina) enlace.setAttribute('aria-current', 'page');
    menu.append(enlace);
  }

  const boton = document.createElement('button');
  boton.type = 'button';
  boton.className = 'boton-menu';
  boton.textContent = '☰ Menú';
  boton.setAttribute('aria-controls', barra.id);
  cabecera.prepend(boton);

  function mostrarBarra(abierta) {
    barra.hidden = !abierta;
    document.body.classList.toggle('menu-abierto', abierta);
    boton.setAttribute('aria-expanded', String(abierta));
  }

  function ajustarPantalla() {
    const teniaFoco = barra.contains(document.activeElement);

    if (movil.matches) {
      cabecera.after(barra);
    } else {
      workspace.before(barra);
    }

    mostrarBarra(!movil.matches);
    if (teniaFoco) boton.focus();
  }

  boton.addEventListener('click', () => mostrarBarra(barra.hidden));
  movil.addEventListener('change', ajustarPantalla);
  ajustarPantalla();
}

// Primero comprobamos la sesión y el acceso, luego cargamos el módulo de la pantalla.
async function iniciar() {
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
    );
    return;
  }

  const cargar = secciones[pagina][2];
  await cargar();
  contenido.hidden = false;
}

window.addEventListener('pageshow', evento => {
  if (evento.persisted) location.reload();
});

iniciar().catch(error => {
  console.error('Error al cargar ' + pagina, error);
  mostrarMensaje(
    'No se pudo cargar la pantalla',
    'Abre la consola del navegador para ver el archivo y la línea del error.',
    'login.html',
  );
});