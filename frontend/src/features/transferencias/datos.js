import { permiteSede, sesionActual } from '../../app/sesion.js';
const transferencias = [
  {
    codigo: 'TR-001',
    origen: 4,
    destino: 2,
    estado: 'EN_TRANSITO',
    despacho: '2026-11-24',
    recepcion: null,
    productos: [
      { sku: 'SE-044', nombre: 'Guantes de seguridad', enviada: 30, recibida: null },
      { sku: 'EM-212', nombre: 'Cinta de embalaje', enviada: 15, recibida: null },
    ],
  },
  {
    codigo: 'TR-002',
    origen: 4,
    destino: 1,
    estado: 'RECIBIDA',
    despacho: '2026-11-20',
    recepcion: '2026-11-21',
    productos: [
      { sku: 'OF-119', nombre: 'Etiquetas adhesivas', enviada: 40, recibida: 40 },
    ],
  },
  {
    codigo: 'TR-003',
    origen: 1,
    destino: 3,
    estado: 'RECIBIDA',
    despacho: '2026-11-21',
    recepcion: '2026-11-23',
    productos: [
      { sku: 'EM-104', nombre: 'Caja corrugada mediana', enviada: 20, recibida: 17 },
      { sku: 'SE-046', nombre: 'Gafas de protección', enviada: 10, recibida: 10 },
    ],
  },
];

export async function listarTransferencias() {
  const cuenta = sesionActual();

  return transferencias.filter(traslado =>
    permiteSede(cuenta, traslado.origen) ||
    permiteSede(cuenta, traslado.destino),
  );
}