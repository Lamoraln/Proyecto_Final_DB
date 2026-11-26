import { consultar, indiceCatalogo } from '../../shared/api.js';

export async function listarOrdenesCompra() {
  const [ordenes, productos, almacenes, proveedores] = await Promise.all([
    consultar('compras/ordenes'),
    indiceCatalogo('productos', 'id_producto'),
    indiceCatalogo('almacenes', 'id_almacen'),
    indiceCatalogo('proveedores', 'id_proveedor'),
  ]);
  const producto = linea => ({
    ...linea,
    sku: productos.get(linea.id_producto)?.sku ?? String(linea.id_producto),
    producto: productos.get(linea.id_producto)?.nombre ?? `Producto #${linea.id_producto}`,
  });
  return ordenes.map(orden => ({
    codigo: 'OC-' + orden.id_orden_compra,
    proveedor: proveedores.get(orden.id_proveedor)?.razon_social ?? `Proveedor #${orden.id_proveedor}`,
    sedeId: almacenes.get(orden.id_almacen_destino)?.id_sede,
    almacen: almacenes.get(orden.id_almacen_destino)?.nombre ?? `Almacén #${orden.id_almacen_destino}`,
    fechaEstimada: orden.fecha_estimada,
    estado: orden.estado,
    lineas: orden.lineas.map(producto),
    recepciones: orden.recepciones.map(r => ({ ...r, lineas: r.lineas.map(producto) })),
  }));
}
