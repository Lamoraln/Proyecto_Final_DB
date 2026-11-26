BEGIN;
CREATE SCHEMA identidad;

-- Configurar el entorno de la sesión para trabajar dentro del esquema 'identidad'
SET search_path TO identidad;

-- =========================================================================
-- 1. TABLAS MAESTRAS (Empleados)
-- =========================================================================

-- Tabla de Empleados (Requerimiento 1 / RN-03)
CREATE TABLE empleados (
    id_empleado SERIAL PRIMARY KEY,
    id_sede INT NOT NULL,                        -- Identificador compartido hacia catalogo.sedes (RN-03)
    tipo_documento VARCHAR(20) NOT NULL,
    num_documento VARCHAR(30) UNIQUE NOT NULL,   -- RC1 / RN-03: Número de documento único por empleado
    nombre_completo VARCHAR(150) NOT NULL,
    cargo VARCHAR(50) NOT NULL,                  -- Cargo como atributo directo (según diseño 3FN)
    correo VARCHAR(100) UNIQUE,                  -- Correo único del empleado
    telefono VARCHAR(30),
    fecha_contratacion DATE,
    estado VARCHAR(20) NOT NULL                  -- Estado operativo del empleado
);

-- =========================================================================
-- 2. TABLAS DE SEGURIDAD Y ACCESOS (Usuarios y Auditoría)
-- =========================================================================

-- Tabla de Usuarios del Sistema (Relación 1:1 con Empleados - Requerimiento 13 / RN-04)
CREATE TABLE usuarios (
    id_usuario SERIAL PRIMARY KEY,
    id_empleado INT UNIQUE NOT NULL REFERENCES empleados(id_empleado) ON UPDATE CASCADE ON DELETE CASCADE, -- RN-04: Un empleado tiene máximo un usuario
    nombre_usuario VARCHAR(50) UNIQUE NOT NULL, -- RC1 / RN-04: Username único
    password_hash VARCHAR(255) NOT NULL,        -- Almacenamiento seguro de contraseña (T7)
    rol VARCHAR(50) CHECK (rol IN ('ADMINISTRADOR', 'GERENCIA', 'RESP_INVENTARIO', 'RESP_COMPRAS', 'VENDEDOR', 'AUDITOR')) NOT NULL, -- Roles del sistema
    estado VARCHAR(20) NOT NULL,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabla de Auditoría de Accesos (Entidad débil dependiente de usuarios - RN-05)
CREATE TABLE auditoria_accesos (
    id_auditoria SERIAL PRIMARY KEY,
    id_usuario INT NOT NULL REFERENCES usuarios(id_usuario) ON UPDATE CASCADE ON DELETE CASCADE,
    fecha_hora TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL, -- Registro automático del evento (RN-05)
    accion VARCHAR(100) NOT NULL,                           -- Acción realizada (LOGIN, CONSULTA, etc.)
    objeto_consultado VARCHAR(150),                         -- Objeto o recurso afectado (RN-05)
    resultado VARCHAR(20) CHECK (resultado IN ('PERMITIDO', 'DENEGADO')) -- Control de acceso (RN-05 / Pruebas)
);
COMMIT;
