const URL_INVENTARIOS = 'http://127.0.0.1:8002/api/inventarios';

async function consultar(url) {
  const respuesta = await fetch(url);

  if (!respuesta.ok) {
    const datos = await respuesta.json().catch(() => ({}));
    throw new Error(datos.detail ?? `La consulta falló con HTTP ${respuesta.status}.`);
  }

  return respuesta.json();
}

export async function listarInventario(sedeId) {
  const [existencias, productos, almacenes] = await Promise.all([
    consultar(`${URL_INVENTARIOS}?sede_id=${encodeURIComponent(sedeId)}`),
    consultar('/api/catalogo/productos').catch(() => []),
    consultar('/api/catalogo/almacenes').catch(() => []),
  ]);

  const productosPorId = new Map(productos.map(p => [p.id_producto, p]));
  const almacenesPorId = new Map(almacenes.map(a => [a.id_almacen, a.nombre]));

  return existencias.map(registro => {
    const producto = productosPorId.get(registro.id_producto);

    return {
      nombre: producto?.nombre ?? `Producto #${registro.id_producto}`,
      sku: producto?.sku ?? '',
      categoria: producto?.categoria ?? '—',
      almacen: almacenesPorId.get(registro.id_almacen)
        ?? `Almacén #${registro.id_almacen}`,
      existencia: registro.existencia,
      minimo: registro.minimo,
    };
  });
}