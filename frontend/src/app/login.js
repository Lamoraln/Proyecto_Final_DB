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
      mensaje.textContent = 'Selecciona un perfil de demostración.';
      return;
    }

    location.replace('./' + paginaInicio(cuenta));
  } catch (error) {
    console.error('Error al guardar la sesión de demostración', error);
    mensaje.textContent = 'No se pudo guardar la sesión en el navegador.';
  }
});