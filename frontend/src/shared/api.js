import { cerrarSesion, tokenActual } from '../app/sesion.js';

export async function consultar(ruta, opciones = {}) {
  const token = tokenActual();
  const respuesta = await fetch('/api/' + ruta, {
    ...opciones,
    headers: { ...(token && { Authorization: 'Bearer ' + token }), ...opciones.headers },
  });

  if (respuesta.status === 401 && token && ruta !== 'identidad/login') {
    cerrarSesion();
    window.location.replace('/login.html');
  }

  const datos = await respuesta.json();
  if (!respuesta.ok) {
    throw new Error(typeof datos.detail === 'string' ? datos.detail : 'Error HTTP ' + respuesta.status);
  }
  return datos;
}

export async function indiceCatalogo(recurso, clave) {
  try {
    return new Map((await consultar('catalogo/' + recurso)).map(item => [item[clave], item]));
  } catch (error) {
    console.warn('Catálogo no disponible para ' + recurso, error);
    return new Map();
  }
}
