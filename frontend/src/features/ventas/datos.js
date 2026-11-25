import { permiteSede, sesionActual } from '../../app/sesion.js';
export const idsSedesComerciales = [1, 2, 3];

const pedidos = [
  {
    codigo: 'PV-001',
    sedeId: 1,
    cliente: 'Comercial Andina',
    fecha: '2026-11-20',
    estado: 'CONFIRMADO',
    lineas: [
      { sku: 'EM-104', producto: 'Caja corrugada mediana', cantidad: 10, precioUnitario: 12000 },
      { sku: 'EM-212', producto: 'Cinta de embalaje', cantidad: 2, precioUnitario: 15000 },
    ],
    pagos: [
      { referencia: 'PG-001', fecha: '2026-11-20', medio: 'Transferencia', valor: 40000, estado: 'CONFIRMADO' },
      { referencia: 'PG-002', fecha: '2026-11-21', medio: 'Efectivo', valor: 30000, estado: 'CONFIRMADO' },
      { referencia: 'PG-003', fecha: '2026-11-24', medio: 'Transferencia', valor: 80000, estado: 'PENDIENTE' },
    ],
  },
  {
    codigo: 'PV-002',
    sedeId: 2,
    cliente: 'Papelería Horizonte',
    fecha: '2026-11-21',
    estado: 'COMPLETADO',
    lineas: [
      { sku: 'OF-119', producto: 'Etiquetas adhesivas', cantidad: 4, precioUnitario: 10000 },
    ],
    pagos: [
      { referencia: 'PG-004', fecha: '2026-11-21', medio: 'Tarjeta', valor: 40000, estado: 'CONFIRMADO' },
    ],
  },
  {
    codigo: 'PV-003',
    sedeId: 3,
    cliente: 'Suministros El Roble',
    fecha: '2026-11-23',
    estado: 'PENDIENTE',
    lineas: [
      { sku: 'SE-044', producto: 'Guantes de seguridad', cantidad: 5, precioUnitario: 16000 },
    ],
    pagos: [],
  },
  {
    codigo: 'PV-004',
    sedeId: 2,
    cliente: 'Empaques del Valle',
    fecha: '2026-11-24',
    estado: 'CANCELADO',
    lineas: [
      { sku: 'EM-305', producto: 'Papel kraft', cantidad: 3, precioUnitario: 9000 },
    ],
    pagos: [
      { referencia: 'PG-005', fecha: '2026-11-24', medio: 'Tarjeta', valor: 27000, estado: 'RECHAZADO' },
    ],
  },
];

export async function listarPedidosVenta() {
  const cuenta = sesionActual();
  return pedidos.filter(pedido => permiteSede(cuenta, pedido.sedeId));
}