BEGIN;
CREATE SCHEMA compras;

-- Configurar el entorno de la sesión para trabajar dentro del esquema 'compras'
SET search_path TO compras;

-- =========================================================================
-- 1. TABLAS TRANSACCIONALES PRINCIPALES (Cabecera)
-- =========================================================================

-- Tabla de Órdenes de Compra (Requerimiento 4 / RN-11, RN-12, RN-15)
CREATE TABLE ordenes_compra (
    id_orden_compra SERIAL PRIMARY KEY,
    id_proveedor INT NOT NULL,           -- Identificador compartido hacia catalogo.proveedores (RN-11)
    id_almacen_destino INT NOT NULL,     -- Identificador compartido hacia catalogo.almacenes (RN-11, S5)
    id_empleado INT NOT NULL,            -- Identificador compartido hacia identidad.empleados (RN-11)
    fecha_orden TIMESTAMP NOT NULL,
    fecha_estimada TIMESTAMP NOT NULL,
    estado VARCHAR(20) CHECK (estado IN ('PENDIENTE', 'PARCIAL', 'RECIBIDA', 'CANCELADA')) NOT NULL, -- RC3 / RN-15
    observaciones TEXT,
    CONSTRAINT chk_fechas_orden CHECK (fecha_estimada >= fecha_orden) -- RC4 / RN-12: Coherencia de fechas
);

-- =========================================================================
-- 2. TABLAS ASOCIATIVAS Y DEPENDIENTES (Detalles y Recepciones)
-- =========================================================================

-- Tabla Asociativa: Detalle de Orden de Compra (Relación N:M con atributos - RN-13, RN-14)
CREATE TABLE detalle_orden_compra (
    id_orden_compra INT NOT NULL REFERENCES ordenes_compra(id_orden_compra) ON UPDATE CASCADE ON DELETE CASCADE,
    id_producto INT NOT NULL,            -- Identificador compartido hacia catalogo.productos
    cantidad_solicitada INT CHECK (cantidad_solicitada > 0) NOT NULL, -- RC2 / RN-13: Cantidad positiva
    costo_unitario NUMERIC(12,2) CHECK (costo_unitario >= 0) NOT NULL, -- RC2 / RN-14: Costo histórico no negativo
    PRIMARY KEY (id_orden_compra, id_producto) -- Llave compuesta evita productos repetidos en la orden (RC6)
);

-- Tabla de Recepciones de Compra (Requerimiento 5 / RN-16)
CREATE TABLE recepciones_compra (
    id_recepcion SERIAL PRIMARY KEY,
    id_orden_compra INT NOT NULL REFERENCES ordenes_compra(id_orden_compra) ON UPDATE CASCADE ON DELETE RESTRICT,
    fecha_recepcion TIMESTAMP NOT NULL,
    estado VARCHAR(20) CHECK (estado IN ('PARCIAL', 'TOTAL')) NOT NULL, -- RC3 / RN-16
    observaciones TEXT
);

-- Tabla Dependiente: Detalle de Recepción (Agregación A1 / RN-17)
CREATE TABLE detalle_recepcion (
    id_recepcion INT NOT NULL REFERENCES recepciones_compra(id_recepcion) ON UPDATE CASCADE ON DELETE CASCADE,
    id_producto INT NOT NULL,            -- Identificador compartido (valida que el producto pertenezca a la orden)
    cantidad_recibida INT CHECK (cantidad_recibida > 0) NOT NULL, -- RC2 / RN-16: Cantidad recibida positiva
    PRIMARY KEY (id_recepcion, id_producto) -- Llave compuesta
);
COMMIT;
