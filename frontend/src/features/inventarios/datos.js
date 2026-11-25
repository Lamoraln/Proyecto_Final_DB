import { permiteSede, sesionActual } from '../../app/sesion.js';

export const todasLassedes = [
  { id: 1, nombre: 'Bogotá Norte', almacen: 'Almacén Norte' },
  { id: 2, nombre: 'Bogotá Sur', almacen: 'Almacén Sur' },
  { id: 3, nombre: 'Medellín', almacen: 'Almacén Medellín' },
  { id: 4, nombre: 'Centro de distribución', almacen: 'Bodega central' },
];

export const sedes = todasLasSedes.filter(
  sede => permiteSede(sesionActual(), sede.id),
);

export async function listarInventario(sedeId) {
  if (!permiteSede(sesionActual(), sedeId)) return [];

  const posicion = todasLasSedes.findIndex(sede => sede.id === Number(sedeId));
  if (posicion === -1) return [];

  return productos.map(({ sku, nombre, categoria, minimo, cantidades }) => ({
    sku,
    nombre,
    categoria,
    almacen: cantidades[posicion] === null ? null : todasLasSedes[posicion].almacen,
    existencia: cantidades[posicion],
    minimo: cantidades[posicion] === null ? null : minimo,
  }));
}