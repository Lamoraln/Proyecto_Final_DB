import { cerrarSesion, guardarSesion, paginaInicio } from './sesion.js';
import { consultar } from '../shared/api.js';

const formulario = document.querySelector('#login-form');
const mensaje = document.querySelector('#login-mensaje');
const boton = formulario.querySelector('button[type=submit]');

formulario.addEventListener('submit', async evento => {
  evento.preventDefault();
  mensaje.textContent = '';
  boton.disabled = true;
  cerrarSesion();

  try {
    const sesion = await consultar('identidad/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        usuario: formulario.querySelector('#usuario').value,
        contrasena: formulario.querySelector('#contrasena').value,
      }),
    });
    guardarSesion(sesion);
    location.replace('./' + paginaInicio(sesion.perfil));
  } catch (error) {
    mensaje.textContent = error.message;
  } finally {
    boton.disabled = false;
  }
});
