BEGIN;
CREATE SCHEMA catalogo;

-- Configurar el entorno para que todas las sentencias siguientes se ejecuten
-- exclusivamente dentro del esquema 'catalogo'
SET search_path TO catalogo;

-- =========================================================================
-- 1. TABLAS MAESTRAS INDEPENDIENTES (Sin dependencias previas)
-- =========================================================================

-- Tabla de Sedes de la organización
CREATE TABLE sedes (
    id_sede INT PRIMARY KEY, -- Identificador manual por sede
    codigo_sede VARCHAR(10) UNIQUE NOT NULL, -- RC1: Código de sede único
    nombre VARCHAR(100) NOT NULL,
    ciudad VARCHAR(50) NOT NULL,
    departamento VARCHAR(50),
    direccion VARCHAR(150),
    telefono VARCHAR(30),
    tipo_sede VARCHAR(20) CHECK (tipo_sede IN ('VENTA', 'DISTRIBUCION')) NOT NULL, -- RC3: Dominio de tipo de sede
    estado VARCHAR(20) CHECK (estado IN ('ACTIVA', 'INACTIVA')) NOT NULL -- RC3: Dominio de estado
);

-- Tabla de Categorías de productos (Relación recursiva padre/hija)
CREATE TABLE categorias (
    id_categoria SERIAL PRIMARY KEY,
    id_categoria_padre INT REFERENCES categorias(id_categoria) ON UPDATE CASCADE ON DELETE SET NULL, -- Llave foránea recursiva
    nombre VARCHAR(100) UNIQUE NOT NULL, -- RC1: Nombre de categoría único
    descripcion TEXT,
    estado VARCHAR(20) NOT NULL,
    CONSTRAINT chk_categoria_padre_distinta CHECK (id_categoria <> id_categoria_padre) -- RC13: Una categoría no es su propia madre
);

-- Tabla de Proveedores comerciales
CREATE TABLE proveedores (
    id_proveedor SERIAL PRIMARY KEY,
    identificacion VARCHAR(50) UNIQUE NOT NULL, -- RC1: Documento/NIT único
    tipo_identificacion VARCHAR(20),
    razon_social VARCHAR(150) NOT NULL,
    ciudad VARCHAR(50),
    direccion VARCHAR(150),
    correo VARCHAR(100),
    telefono VARCHAR(30),
    estado VARCHAR(20) NOT NULL
);

-- Tabla de Clientes
CREATE TABLE clientes (
    id_cliente SERIAL PRIMARY KEY,
    tipo_documento VARCHAR(20) NOT NULL,
    num_documento VARCHAR(30) NOT NULL,
    nombre_completo VARCHAR(150) NOT NULL,
    correo VARCHAR(100),
    telefono VARCHAR(30),
    direccion VARCHAR(150),
    ciudad VARCHAR(50),
    tipo_cliente VARCHAR(20) CHECK (tipo_cliente IN ('NATURAL', 'JURIDICO')), -- RC3: Dominio de tipo de cliente
    estado VARCHAR(20) NOT NULL,
    CONSTRAINT uq_cliente_documento UNIQUE (tipo_documento, num_documento) -- RC1: Unicidad de documento por tipo
);

-- =========================================================================
-- 2. TABLAS MAESTRAS DEPENDIENTES (Dependen de las independientes)
-- =========================================================================

-- Tabla de Almacenes o bodegas pertenecientes a sedes
CREATE TABLE almacenes (
    id_almacen SERIAL PRIMARY KEY,
    id_sede INT NOT NULL REFERENCES sedes(id_sede) ON UPDATE CASCADE ON DELETE RESTRICT, -- FK local a sedes
    codigo_almacen VARCHAR(20) UNIQUE NOT NULL, -- RC1: Código de almacén único
    nombre VARCHAR(100) NOT NULL,
    tipo_almacen VARCHAR(30) CHECK (tipo_almacen IN ('PRINCIPAL', 'SECUNDARIO', 'DISTRIBUCION')) NOT NULL, -- RC3: Dominio de tipo
    capacidad NUMERIC(12,2) CHECK (capacidad >= 0), -- RC2: Capacidad no negativa
    estado VARCHAR(20) NOT NULL
);

-- Tabla de Productos del catálogo
CREATE TABLE productos (
    id_producto SERIAL PRIMARY KEY,
    sku VARCHAR(50) UNIQUE NOT NULL, -- RC1: SKU único por producto
    nombre VARCHAR(150) NOT NULL,
    descripcion TEXT,
    id_categoria INT NOT NULL REFERENCES categorias(id_categoria) ON UPDATE CASCADE ON DELETE RESTRICT, -- FK local a categorías
    unidad_medida VARCHAR(20) NOT NULL,
    precio_lista NUMERIC(12,2) CHECK (precio_lista >= 0) NOT NULL, -- RC2: Precio no negativo
    marca VARCHAR(50),
    estado VARCHAR(20) CHECK (estado IN ('ACTIVO', 'INACTIVO')) NOT NULL -- RC3: Dominio de estado
);

-- =========================================================================
-- 3. TABLAS DE ROMPIMIENTO / ASOCIATIVAS (Dependen de dos maestras)
-- =========================================================================

-- Tabla asociativa N:M entre Productos y Proveedores (Suministra)
CREATE TABLE producto_proveedor (
    id_producto INT NOT NULL REFERENCES productos(id_producto) ON UPDATE CASCADE ON DELETE CASCADE, -- FK local a productos
    id_proveedor INT NOT NULL REFERENCES proveedores(id_proveedor) ON UPDATE CASCADE ON DELETE CASCADE, -- FK local a proveedores
    costo_referencia NUMERIC(12,2) CHECK (costo_referencia >= 0) NOT NULL, -- RC2: Costo no negativo
    plazo_entrega_dias INT CHECK (plazo_entrega_dias >= 0) NOT NULL, -- RC2: Plazo no negativo
    proveedor_preferido BOOLEAN DEFAULT FALSE,
    PRIMARY KEY (id_producto, id_proveedor) -- RC6: Clave primaria compuesta (evita duplicados)
);
COMMIT;
