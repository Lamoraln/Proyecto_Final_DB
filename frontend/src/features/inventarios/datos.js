import { permiteSede, sesionActual } from '../../app/sesion.js';

export const todasLasSedes = [
  { id: 1, nombre: 'Bogotá Norte', almacen: 'Almacén Norte' },
  { id: 2, nombre: 'Bogotá Sur', almacen: 'Almacén Sur' },
  { id: 3, nombre: 'Medellín', almacen: 'Almacén Medellín' },
  { id: 4, nombre: 'Centro de distribución', almacen: 'Bodega central' },
];

export const sedes = todasLasSedes.filter(
  sede => permiteSede(sesionActual(), sede.id),
);

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