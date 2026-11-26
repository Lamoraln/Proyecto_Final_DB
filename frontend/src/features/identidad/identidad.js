import { consultar, indiceCatalogo } from '../../shared/api.js';
import { montarDirectorio, mostrarErrorConsulta } from '../../shared/directorio.js';

const contenedor = document.querySelector('#directorio');

try {
  const [directorio, sedes] = await Promise.all([
    consultar('identidad/directorio'), indiceCatalogo('sedes', 'id_sede'),
  ]);
  montarDirectorio(contenedor, [
    {
      titulo: 'Empleados',
      columnas: ['ID', 'Empleado', 'Sede', 'Cargo', 'Estado'],
      filas: directorio.empleados.map(e => [
        e.id_empleado, e.nombre_completo, sedes.get(e.id_sede)?.nombre ?? e.id_sede, e.cargo, e.estado,
      ]),
    },
    {
      titulo: 'Cuentas',
      columnas: ['Usuario', 'Empleado', 'Rol', 'Estado'],
      filas: directorio.usuarios.map(u => [u.nombre_usuario, u.nombre_completo, u.rol, u.estado]),
    },
    {
      titulo: 'Auditoría registrada',
      columnas: ['Fecha y hora', 'Usuario', 'Acción', 'Recurso', 'Resultado'],
      filas: directorio.auditoria.map(a => [
        a.fecha_hora.replace('T', ' '), a.nombre_usuario, a.accion, a.objeto_consultado, a.resultado,
      ]),
    },
  ], 'Información');
} catch (error) {
  mostrarErrorConsulta(contenedor, error);
}
