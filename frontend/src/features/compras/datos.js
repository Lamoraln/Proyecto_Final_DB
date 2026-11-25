import { permiteSede, sesionActual } from '../../app/sesion.js';
const ordenes = [
  {
    codigo: 'OC-001',
    proveedor: 'Suministros Andinos',
    sedeId: 2,
    fechaEstimada: '2026-11-28',
    estado: 'PENDIENTE',
    lineas: [
      { sku: 'SE-044', producto: 'Guantes de seguridad', solicitada: 30 },
    ],
    recepciones: [],
  },
  {
    codigo: 'OC-002',
    proveedor: 'Empaques del Centro',
    sedeId: 1,
    fechaEstimada: '2026-11-26',
    estado: 'PARCIAL',
    lineas: [
      { sku: 'EM-104', producto: 'Caja corrugada mediana', solicitada: 20 },
      { sku: 'EM-212', producto: 'Cinta de embalaje', solicitada: 10 },
    ],
    recepciones: [
      {
        codigo: 'RC-001',
        lineas: [
          { sku: 'EM-104', cantidad: 6 },
          { sku: 'EM-212', cantidad: 10 },
        ],
      },
      {
        codigo: 'RC-002',
        lineas: [
          { sku: 'EM-104', cantidad: 8 },
        ],
      },
    ],
  },
  {
    codigo: 'OC-003',
    proveedor: 'Papelería Industrial',
    sedeId: 3,
    fechaEstimada: '2026-11-23',
    estado: 'RECIBIDA',
    lineas: [
      { sku: 'OF-119', producto: 'Etiquetas adhesivas', solicitada: 40 },
    ],
    recepciones: [
      {
        codigo: 'RC-003',
        lineas: [
          { sku: 'OF-119', cantidad: 40 },
        ],
      },
    ],
  },
];

export async function listarOrdenesCompra() {
  const cuenta = sesionActual();
  return ordenes.filter(orden => permiteSede(cuenta, orden.sedeId));
}