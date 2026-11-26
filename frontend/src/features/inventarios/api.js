import { consultar, indiceCatalogo } from '../../shared/api.js';

export async function listarInventario(sedeId) {
  const [existencias, productos, almacenes] = await Promise.all([
    consultar('inventarios?sede_id=' + encodeURIComponent(sedeId)),
    indiceCatalogo('productos', 'id_producto'),
    indiceCatalogo('almacenes', 'id_almacen'),
  ]);
  const registrados = new Set(existencias.map(item => item.id_producto));
  const filas = existencias.map(registro => {
    const producto = productos.get(registro.id_producto);
    return {
      ...registro,
      nombre: producto?.nombre ?? `Producto #${registro.id_producto}`,
      sku: producto?.sku ?? String(registro.id_producto),
      categoria: producto?.categoria ?? '—',
      almacen: almacenes.get(registro.id_almacen)?.nombre ?? `Almacén #${registro.id_almacen}`,
    };
  });
  for (const p of productos.values()) {
    if (p.estado === 'ACTIVO' && !registrados.has(p.id_producto)) {
      filas.push({ nombre: p.nombre, sku: p.sku, categoria: p.categoria ?? '—',
        almacen: null, existencia: null, minimo: null });
    }
  }
  return filas;
}

export function guardarMinimo(fila, minimo) {
  return consultar(`inventarios/${fila.id_sede}/${fila.id_almacen}/${fila.id_producto}/minimo`, {
    method: 'PATCH',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ minimo }),
  });
}
