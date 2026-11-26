import { consultar, indiceCatalogo } from '../../shared/api.js';

export async function listarPedidosVenta() {
  const [pedidos, productos, clientes] = await Promise.all([
    consultar('ventas/pedidos'),
    indiceCatalogo('productos', 'id_producto'),
    indiceCatalogo('clientes', 'id_cliente'),
  ]);
  return pedidos.map(p => ({
    codigo: 'PV-' + p.id_pedido,
    sedeId: p.id_sede,
    cliente: clientes.get(p.id_cliente)?.nombre_completo ?? `Cliente #${p.id_cliente}`,
    fecha: p.fecha_pedido,
    estado: p.estado,
    total: Number(p.total_registrado),
    lineas: p.lineas.map(l => ({
      ...l,
      producto: productos.get(l.id_producto)?.nombre ?? `Producto #${l.id_producto}`,
      sku: productos.get(l.id_producto)?.sku ?? String(l.id_producto),
    })),
    pagos: p.pagos,
  }));
}
