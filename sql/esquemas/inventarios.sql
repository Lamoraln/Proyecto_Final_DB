BEGIN;
CREATE SCHEMA inventarios;

-- Configurar el entorno de la sesión para trabajar dentro del esquema 'inventarios'
SET search_path TO inventarios;

-- =========================================================================
-- 1. TABLA OPERACIONAL FRAGMENTADA (Inventarios por Sede)
-- =========================================================================

-- Tabla de Inventarios (Fragmentada horizontalmente por sede - Requerimiento 6 y 15 / RN-19, RN-20)
CREATE TABLE inventarios (
    id_sede INT NOT NULL,                  -- Atributo de fragmentación horizontal corporativa (RN-49)
    id_almacen INT NOT NULL,               -- Identificador compartido hacia catalogo.almacenes (RN-19)
    id_producto INT NOT NULL,              -- Identificador compartido hacia catalogo.productos (RN-19)
    existencia_actual INT CHECK (existencia_actual >= 0) NOT NULL, -- RC2 / RN-20: Stock físico no negativo
    stock_minimo INT CHECK (stock_minimo >= 0) NOT NULL,           -- RC2 / RN-20: Mínimo requerido de reorden
    fecha_actualizacion TIMESTAMP NOT NULL,                        -- Estampa de último movimiento (RN-25)
    PRIMARY KEY (id_sede, id_almacen, id_producto)                 -- Llave primaria compuesta que asegura unicidad por sede/almacén/producto (RN-19)
) PARTITION BY LIST (id_sede);
CREATE TABLE inventarios.inventario_sede_01 PARTITION OF inventarios.inventarios FOR VALUES IN (1);
CREATE TABLE inventarios.inventario_sede_02 PARTITION OF inventarios.inventarios FOR VALUES IN (2);
CREATE TABLE inventarios.inventario_sede_03 PARTITION OF inventarios.inventarios FOR VALUES IN (3);
CREATE TABLE inventarios.inventario_sede_04 PARTITION OF inventarios.inventarios FOR VALUES IN (4);

-- =========================================================================
-- 2. TABLAS DE TRANSFERENCIAS LOGÍSTICAS (Origen a Destino)
-- =========================================================================

-- Tabla de Transferencias (Requerimiento 9 / RN-26, RN-27, RN-28)
CREATE TABLE transferencias (
    id_transferencia SERIAL PRIMARY KEY,
    id_almacen_origen INT NOT NULL,        -- Identificador compartido (Bodega de salida) (RN-26)
    id_almacen_destino INT NOT NULL,       -- Identificador compartido (Bodega receptora) (RN-26)
    fecha_solicitud TIMESTAMP NOT NULL,
    fecha_despacho TIMESTAMP,              -- Fecha de salida logística (RN-27)
    fecha_recepcion TIMESTAMP,             -- Fecha de llegada a destino (RN-27)
    estado VARCHAR(20) CHECK (estado IN ('SOLICITADA', 'EN_TRANSITO', 'RECIBIDA', 'CANCELADA')) NOT NULL, -- RC3 / RN-28
    observaciones TEXT,
    CONSTRAINT chk_almacenes_distintos CHECK (id_almacen_origen <> id_almacen_destino), -- RC5 / RN-26: El origen y destino no pueden ser iguales
    CONSTRAINT chk_fechas_transf CHECK (                                            -- RC4 / RN-27: Coherencia temporal de estados
        (fecha_despacho IS NULL OR fecha_despacho >= fecha_solicitud) AND
        (fecha_recepcion IS NULL OR fecha_recepcion >= fecha_despacho)
    )
);

-- Tabla Asociativa: Detalle de Transferencia (Requerimiento 9 / RN-29, RN-31)
CREATE TABLE detalle_transferencia (
    id_transferencia INT NOT NULL REFERENCES transferencias(id_transferencia) ON UPDATE CASCADE ON DELETE CASCADE,
    id_producto INT NOT NULL,              -- Identificador compartido hacia catalogo.productos (RN-31)
    cantidad_enviada INT CHECK (cantidad_enviada > 0) NOT NULL, -- RC2 / RN-29: Unidades despachadas estrictamente mayores a cero
    cantidad_recibida INT CHECK (cantidad_recibida >= 0),       -- RC2 / RN-29: Nula hasta la recepción física
    PRIMARY KEY (id_transferencia, id_producto)                 -- Llave compuesta evita duplicar el mismo producto en una transferencia (RC6 / RN-31)
);
COMMIT;
