BEGIN;
CREATE SCHEMA ventas;

-- Configurar el entorno de la sesión para trabajar dentro del esquema 'ventas'
SET search_path TO ventas;

-- =========================================================================
-- 1. TABLA TRANSACCIONAL FRAGMENTADA (Cabecera de Pedidos)
-- =========================================================================

-- Tabla de Pedidos de Venta (Fragmentada horizontalmente por sede - Requerimiento 7 y 15 / RN-32, RN-33, RN-36)
CREATE TABLE pedidos_venta (
    id_sede INT NOT NULL,                  -- Criterio de fragmentación horizontal corporativa
    id_pedido INT NOT NULL,                -- Identificador secuencial del pedido
    id_almacen INT NOT NULL,               -- Identificador compartido hacia catalogo.almacenes (S4)
    id_cliente INT NOT NULL,               -- Identificador compartido hacia catalogo.clientes (RN-32)
    id_empleado INT NOT NULL,              -- Identificador compartido hacia identidad.empleados (RN-32)
    fecha_pedido TIMESTAMP NOT NULL,
    estado VARCHAR(20) CHECK (estado IN ('PENDIENTE', 'CONFIRMADO', 'COMPLETADO', 'CANCELADO')) NOT NULL, -- RC3 / RN-33
    total_registrado NUMERIC(12,2) CHECK (total_registrado >= 0) NOT NULL, -- RC2 / RN-36: Redundancia controlada de importe total
    observaciones TEXT,
    PRIMARY KEY (id_sede, id_pedido)       -- Llave primaria compuesta por sede y pedido para la fragmentación horizontal
) PARTITION BY LIST (id_sede);
CREATE TABLE ventas.pedido_venta_sede_01 PARTITION OF ventas.pedidos_venta FOR VALUES IN (1);
CREATE TABLE ventas.pedido_venta_sede_02 PARTITION OF ventas.pedidos_venta FOR VALUES IN (2);
CREATE TABLE ventas.pedido_venta_sede_03 PARTITION OF ventas.pedidos_venta FOR VALUES IN (3);
CREATE TABLE ventas.pedido_venta_sede_04 PARTITION OF ventas.pedidos_venta FOR VALUES IN (4);

-- =========================================================================
-- 2. TABLAS ASOCIATIVAS Y DEPENDIENTES (Detalles, Pagos y Devoluciones)
-- =========================================================================

-- Tabla Asociativa: Detalle de Pedido (Relación N:M - Requerimiento 7 / RN-34, RN-35)
CREATE TABLE detalle_pedido (
    id_sede INT NOT NULL,
    id_pedido INT NOT NULL,
    id_producto INT NOT NULL,              -- Identificador compartido hacia catalogo.productos (RN-34)
    cantidad INT CHECK (cantidad > 0) NOT NULL, -- RC2 / RN-34: Unidades vendidas positivas
    precio_unitario NUMERIC(12,2) CHECK (precio_unitario >= 0) NOT NULL, -- RC2 / RN-35: Precio histórico pactado
    PRIMARY KEY (id_sede, id_pedido, id_producto), -- Llave compuesta que evita productos repetidos en el pedido (RC6)
    FOREIGN KEY (id_sede, id_pedido) REFERENCES pedidos_venta(id_sede, id_pedido) ON UPDATE CASCADE ON DELETE CASCADE
);

-- Tabla de Pagos (Débil / Dependiente de Pedido - Requerimiento 8 / RN-37)
CREATE TABLE pagos (
    id_pago SERIAL PRIMARY KEY,
    id_sede INT NOT NULL,                  -- Parte de la llave foránea compuesta hacia el pedido
    id_pedido INT NOT NULL,                -- Parte de la llave foránea compuesta hacia el pedido
    referencia_pago VARCHAR(50) UNIQUE NOT NULL, -- RC1 / RN-37: Voucher o código de transacción único
    fecha_pago TIMESTAMP NOT NULL,
    valor NUMERIC(12,2) CHECK (valor > 0) NOT NULL, -- RC2 / RN-37: Monto abonado estrictamente positivo
    medio_pago VARCHAR(30) CHECK (medio_pago IN ('EFECTIVO', 'TARJETA', 'TRANSFERENCIA', 'OTRO')) NOT NULL, -- RC3 / RN-37
    estado VARCHAR(20) CHECK (estado IN ('CONFIRMADO', 'PENDIENTE', 'RECHAZADO')) NOT NULL, -- RC3 / RN-37
    FOREIGN KEY (id_sede, id_pedido) REFERENCES pedidos_venta(id_sede, id_pedido) ON UPDATE CASCADE ON DELETE RESTRICT
);

-- Tabla de Devoluciones (Requerimiento 10 / RN-43)
CREATE TABLE devoluciones (
    id_devolucion SERIAL PRIMARY KEY,
    id_sede INT NOT NULL,                  -- Parte de la llave foránea compuesta hacia el pedido
    id_pedido INT NOT NULL,                -- Parte de la llave foránea compuesta hacia el pedido
    fecha_solicitud TIMESTAMP NOT NULL,
    motivo TEXT NOT NULL,                  -- Explicación del reclamo (RN-43)
    estado VARCHAR(20) CHECK (estado IN ('SOLICITADA', 'APROBADA', 'RECHAZADA')) NOT NULL, -- RC3
    FOREIGN KEY (id_sede, id_pedido) REFERENCES pedidos_venta(id_sede, id_pedido) ON UPDATE CASCADE ON DELETE RESTRICT
);

-- Tabla Dependiente: Detalle de Devolución (Agregación A2 / RN-44, RN-45)
CREATE TABLE detalle_devolucion (
    id_devolucion INT NOT NULL REFERENCES devoluciones(id_devolucion) ON UPDATE CASCADE ON DELETE CASCADE,
    id_producto INT NOT NULL,              -- Identificador compartido del producto devuelto
    id_sede INT NOT NULL,                  -- Sede de la venta original para el validador
    id_pedido INT NOT NULL,                -- Pedido original de la venta
    cantidad INT CHECK (cantidad > 0) NOT NULL, -- RC2 / RN-44: Unidades reintegradas positivas
    condicion_producto VARCHAR(30) CHECK (condicion_producto IN ('BUEN_ESTADO', 'DANADO', 'DEFECTUOSO')) NOT NULL, -- RC3 / RN-45
    PRIMARY KEY (id_devolucion, id_producto),
    -- Llave foránea compuesta que asegura que el producto devuelto pertenezca estrictamente al detalle del pedido original (RC14 / RN-44)
    FOREIGN KEY (id_sede, id_pedido, id_producto) REFERENCES detalle_pedido(id_sede, id_pedido, id_producto) ON UPDATE CASCADE ON DELETE RESTRICT
);
COMMIT;
