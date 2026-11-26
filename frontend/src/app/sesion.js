const paginasPorRol = {
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

const clave = 'distribured.sesion';

function leerSesion() {
  try {
    const sesion = JSON.parse(sessionStorage.getItem(clave));
    if (sesion?.expira * 1000 > Date.now()) return sesion;
  } catch {
    // Volver al formulario si la sesión local está dañada.
  }
  cerrarSesion();
  return null;
}

export function guardarSesion(sesion) {
  sessionStorage.setItem(clave, JSON.stringify(sesion));
}

export function sesionActual() {
  return leerSesion()?.perfil ?? null;
}

export function tokenActual() {
  return leerSesion()?.token ?? null;
}

export function cerrarSesion() {
  sessionStorage.removeItem(clave);
}

export function permitePantalla(cuenta, pagina) {
  return paginasPorRol[cuenta?.rol]?.includes(pagina) ?? false;
}

export function paginaInicio(cuenta) {
  return paginasPorRol[cuenta?.rol]?.[0] ?? 'login.html';
}

export function permiteSede(cuenta, sedeId) {
  return Boolean(cuenta && (
    cuenta.sedes === null || cuenta.sedes.includes(Number(sedeId))
  ));
}
