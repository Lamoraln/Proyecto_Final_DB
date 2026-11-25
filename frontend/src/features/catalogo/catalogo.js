import { listarInventario, sedes } from '../inventarios/datos.js';
import { listarOrdenesCompra } from '../compras/datos.js';
import { listarPedidosVenta } from '../ventas/datos.js';
import { montarDirectorio, mostrarErrorConsulta } from '../../shared/directorio.js';

const contenedor = document.querySelector('#directorio');

try {
  const [inventarios, compras, ventas] = await Promise.all([
    Promise.all(sedes.map(sede => listarInventario(sede.id))),
    listarOrdenesCompra(),
    listarPedidosVenta(),
  ]);

  const productos = [...new Map(
    inventarios.flat().map(producto => [producto.sku, producto]),
  ).values()];

  const categorias = [...new Set(productos.map(producto => producto.categoria))];
  const proveedores = [...new Set(compras.map(orden => orden.proveedor))];
  const clientes = [...new Set(ventas.map(pedido => pedido.cliente))];

  montarDirectorio(contenedor, [
    {
      titulo: 'Productos',
      columnas: ['SKU', 'Nombre', 'Categoría'],
      filas: productos.map(p => [p.sku, p.nombre, p.categoria]),
    },
    {
      titulo: 'Categorías',
      columnas: ['Categoría', 'Referencias'],
      filas: categorias.map(categoria => [
        categoria,
        productos.filter(p => p.categoria === categoria).length,
      ]),
    },
    {
      titulo: 'Proveedores',
      columnas: ['Proveedor', 'Órdenes de demostración'],
      filas: proveedores.map(proveedor => [
        proveedor,
        compras.filter(orden => orden.proveedor === proveedor).length,
      ]),
    },
    {
      titulo: 'Clientes',
      columnas: ['Cliente', 'Pedidos de demostración'],
      filas: clientes.map(cliente => [
        cliente,
        ventas.filter(pedido => pedido.cliente === cliente).length,
      ]),
    },
    {
      titulo: 'Sedes y almacenes',
      columnas: ['Sede', 'Almacén'],
      filas: sedes.map(sede => [sede.nombre, sede.almacen]),
    },
  ], 'Catálogo');
} catch (error) {
  mostrarErrorConsulta(contenedor, error);
}