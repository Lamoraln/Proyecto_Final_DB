import { permiteSede, sesionActual } from '../../app/sesion.js';
import { indiceCatalogo } from '../../shared/api.js';

const maestras = await indiceCatalogo('sedes', 'id_sede');
const cuenta = sesionActual();
const ids = maestras.size ? [...maestras.keys()] : cuenta?.sedes ?? [1, 2, 3, 4];

export const todasLasSedes = ids.sort((a, b) => a - b).map(id => ({
  id,
  nombre: maestras.get(id)?.nombre ?? `Sede #${id}`,
  tipo: maestras.get(id)?.tipo_sede,
}));

export const sedes = todasLasSedes.filter(sede => permiteSede(cuenta, sede.id));
