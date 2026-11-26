from fastapi import Depends

from comun import BaseDatos, permitir, servicio, sesion

db = BaseDatos(__file__, "db_catalogo")
app = servicio("Catálogo y Terceros", db)
consultar = db.consultar

@app.get("/api/catalogo/conexion")
def verificar_conexion(_=Depends(permitir("ADMINISTRADOR"))):
    return consultar("SELECT current_database() AS base")[0]


# Son datos de referencia que también usan las demás pantallas.
@app.get("/api/catalogo/sedes")
def listar_sedes(_=Depends(sesion)):
    return consultar("""
        SELECT id_sede, codigo_sede, nombre, ciudad, tipo_sede, estado
        FROM catalogo.sedes
        ORDER BY nombre, id_sede
    """)


@app.get("/api/catalogo/almacenes")
def listar_almacenes(_=Depends(sesion)):
    return consultar("""
        SELECT a.id_almacen, a.codigo_almacen, a.nombre, a.id_sede,
               s.nombre AS sede, a.tipo_almacen, a.estado
        FROM catalogo.almacenes AS a
        JOIN catalogo.sedes AS s ON s.id_sede = a.id_sede
        ORDER BY s.nombre, a.nombre, a.id_almacen
    """)


@app.get("/api/catalogo/productos")
def listar_productos(_=Depends(sesion)):
    return consultar("""
        SELECT p.id_producto, p.sku, p.nombre, c.nombre AS categoria, p.estado
        FROM catalogo.productos AS p
        LEFT JOIN catalogo.categorias AS c ON c.id_categoria = p.id_categoria
        ORDER BY p.nombre, p.sku
    """)


@app.get("/api/catalogo/categorias")
def listar_categorias(_=Depends(sesion)):
    return consultar("""
        SELECT c.id_categoria, c.nombre, COUNT(p.id_producto) AS referencias
        FROM catalogo.categorias AS c
        LEFT JOIN catalogo.productos AS p ON p.id_categoria = c.id_categoria
        GROUP BY c.id_categoria, c.nombre
        ORDER BY c.nombre, c.id_categoria
    """)


# Proveedores y clientes tienen permisos más específicos que el catálogo básico.
@app.get("/api/catalogo/proveedores")
def listar_proveedores(_=Depends(permitir("ADMINISTRADOR", "RESP_COMPRAS"))):
    return consultar("""
        SELECT id_proveedor, razon_social, ciudad, estado
        FROM catalogo.proveedores
        ORDER BY razon_social, id_proveedor
    """)


@app.get("/api/catalogo/clientes")
def listar_clientes(_=Depends(permitir("ADMINISTRADOR", "VENDEDOR"))):
    return consultar("""
        SELECT id_cliente, nombre_completo, tipo_cliente, estado
        FROM catalogo.clientes
        ORDER BY nombre_completo, id_cliente
    """)
