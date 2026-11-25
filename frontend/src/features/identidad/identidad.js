import { sedes } from '../inventarios/datos.js';
import { montarDirectorio } from '../../shared/directorio.js';

const sedesPorId = new Map(sedes.map(sede => [sede.id, sede.nombre]));

const empleados = [
  { id: 'EMP-001', nombre: 'Sara Torres', sedeId: 1, cargo: 'Gerente' },
  { id: 'EMP-002', nombre: 'Daniel Rojas', sedeId: 2, cargo: 'Vendedor' },
  { id: 'EMP-003', nombre: 'Laura Vega', sedeId: 4, cargo: 'Responsable de inventario' },
];

const cuentas = [
  { usuario: 'sara.torres', empleadoId: 'EMP-001', rol: 'GERENCIA', estado: 'ACTIVA' },
  { usuario: 'daniel.rojas', empleadoId: 'EMP-002', rol: 'VENDEDOR', estado: 'ACTIVA' },
  { usuario: 'laura.vega', empleadoId: 'EMP-003', rol: 'RESP_INVENTARIO', estado: 'ACTIVA' },
];

const empleadosPorId = new Map(empleados.map(empleado => [empleado.id, empleado.nombre]));

montarDirectorio(document.querySelector('#directorio'), [
  {
    titulo: 'Empleados',
    columnas: ['Código', 'Empleado', 'Sede', 'Cargo'],
    filas: empleados.map(e => [e.id, e.nombre, sedesPorId.get(e.sedeId), e.cargo]),
  },
  {
    titulo: 'Cuentas',
    columnas: ['Usuario', 'Empleado', 'Perfil', 'Estado'],
    filas: cuentas.map(c => [c.usuario, empleadosPorId.get(c.empleadoId), c.rol, c.estado]),
  },
  {
    titulo: 'Perfiles funcionales',
    columnas: ['Perfil', 'Alcance previsto'],
    filas: [
      ['ADMINISTRADOR', 'Administra usuarios, esquemas y permisos'],
      ['GERENCIA', 'Consulta reportes corporativos'],
      ['RESP_INVENTARIO', 'Gestiona existencias y traslados de sedes autorizadas'],
      ['RESP_COMPRAS', 'Gestiona órdenes y recepciones autorizadas'],
      ['VENDEDOR', 'Registra y consulta pedidos y pagos de su sede'],
      ['AUDITOR', 'Consulta información y reportes autorizados'],
    ],
  },
  {
    titulo: 'Auditoría',
    columnas: ['Fecha y hora', 'Usuario', 'Acción', 'Recurso', 'Resultado'],
    filas: [
      ['24/11/2026 09:00', 'sara.torres', 'SELECT', 'Reporte corporativo', 'PERMITIDO'],
      ['24/11/2026 09:12', 'daniel.rojas', 'UPDATE', 'Catálogo de productos', 'DENEGADO'],
      ['24/11/2026 09:25', 'laura.vega', 'SELECT', 'Inventario de bodega central', 'PERMITIDO'],
    ],
  },
], 'Información');