import { consultar } from '../../shared/api.js';
import {
  montarDirectorio,
  mostrarErrorConsulta,
} from '../../shared/directorio.js';

const contenedor = document.querySelector('#directorio');


try {
  const [productos, categorias, proveedores, clientes, sedes, almacenes] =
    await Promise.all([
      consultar('catalogo/productos'),
      consultar('catalogo/categorias'),
      consultar('catalogo/proveedores'),
      consultar('catalogo/clientes'),
      consultar('catalogo/sedes'),
      consultar('catalogo/almacenes'),
    ]);

  montarDirectorio(contenedor, [
    {
      titulo: 'Productos',
      columnas: ['SKU', 'Nombre', 'Categoría', 'Estado'],
      filas: productos.map(p => [p.sku, p.nombre, p.categoria, p.estado]),
    },
    {
      titulo: 'Categorías',
      columnas: ['Categoría', 'Referencias'],
      filas: categorias.map(c => [c.nombre, c.referencias]),
    },
    {
      titulo: 'Proveedores',
      columnas: ['Proveedor', 'Ciudad', 'Estado'],
      filas: proveedores.map(p => [p.razon_social, p.ciudad, p.estado]),
    },
    {
      titulo: 'Clientes',
      columnas: ['Cliente', 'Tipo', 'Estado'],
      filas: clientes.map(c => [c.nombre_completo, c.tipo_cliente, c.estado]),
    },
    {
      titulo: 'Sedes',
      columnas: ['Código', 'Sede', 'Ciudad', 'Tipo', 'Estado'],
      filas: sedes.map(s => [s.codigo_sede, s.nombre, s.ciudad, s.tipo_sede, s.estado]),
    },
    {
      titulo: 'Almacenes',
      columnas: ['Código', 'Almacén', 'Sede', 'Tipo', 'Estado'],
      filas: almacenes.map(a => [a.codigo_almacen, a.nombre, a.sede, a.tipo_almacen, a.estado]),
    },
  ], 'Catálogo');
} catch (error) {
  mostrarErrorConsulta(contenedor, error);
}