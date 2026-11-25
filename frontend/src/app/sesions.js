export const cuentasDemo = [
  { id: 'administrador', nombre: 'Administrador', rol: 'ADMINISTRADOR', sedes: null },
  { id: 'gerencia', nombre: 'Gerencia', rol: 'GERENCIA', sedes: null },
  { id: 'inventario', nombre: 'Responsable de inventario', rol: 'RESP_INVENTARIO', sedes: [1, 4] },
  { id: 'compras', nombre: 'Responsable de compras', rol: 'RESP_COMPRAS', sedes: [1, 2] },
  { id: 'vendedor', nombre: 'Vendedor · Bogotá Sur', rol: 'VENDEDOR', sedes: [2] },
  { id: 'auditor', nombre: 'Auditor', rol: 'AUDITOR', sedes: null },
];

const clave = 'distribured.cuenta-demo';

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

export function sesionActual() {
  const id = sessionStorage.getItem(clave);
  return cuentasDemo.find(cuenta => cuenta.id === id) ?? null;
}

export function iniciarSesionDemo(id) {
  const cuenta = cuentasDemo.find(item => item.id === id);
  if (!cuenta) return null;

  sessionStorage.setItem(clave, cuenta.id);
  return cuenta;
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