import { consultar, indiceCatalogo } from '../../shared/api.js';

export async function listarTransferencias() {
  const [traslados, productos, almacenes] = await Promise.all([
    consultar('inventarios/transferencias'),
    indiceCatalogo('productos', 'id_producto'),
    indiceCatalogo('almacenes', 'id_almacen'),
  ]);
  function nombreAlmacen(id) {
    const almacen = almacenes.get(id);
    return almacen ? `${almacen.sede} · ${almacen.nombre}` : `Almacén #${id}`;
  }
  return traslados.map(t => ({
    codigo: 'TR-' + t.id_transferencia,
    origen: nombreAlmacen(t.id_almacen_origen),
    destino: almacenes.get(t.id_almacen_destino)?.id_sede,
    almacenDestino: nombreAlmacen(t.id_almacen_destino),
    despacho: t.fecha_despacho,
    recepcion: t.fecha_recepcion,
    estado: t.estado,
    productos: t.productos.map(p => ({
      ...p,
      sku: productos.get(p.id_producto)?.sku ?? String(p.id_producto),
      nombre: productos.get(p.id_producto)?.nombre ?? `Producto #${p.id_producto}`,
    })),
  }));
}
