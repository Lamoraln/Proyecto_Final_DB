#!/usr/bin/env bash
# Instala la capa de datos de DistribuRed en una instancia PostgreSQL vacía
# y ejecuta las pruebas de sql/pruebas. Sigue el orden de documents/instalacion-sql.md.
#
# Variables de entorno:
#   PGHOST, PGPORT, PGUSER  instancia y superusuario (debe poder crear bases y roles)
#   PGPASSWORD              contraseña del superusuario, si la instancia la pide
#   REPORTES_CLAVE          contraseña de distribured_reportes (lector de Reportes)
#
# El FDW de Reportes conecta por TCP con sslmode=require y exige autenticación
# por contraseña, así que la instancia debe aceptar SSL y scram-sha-256 en TCP.
set -euo pipefail

RAIZ="$(cd "$(dirname "$0")/.." && pwd)"
cd "$RAIZ"

: "${REPORTES_CLAVE:?Defina REPORTES_CLAVE con la contraseña de distribured_reportes.}"
HOST_FDW="${PGHOST:-localhost}"
PSQL=(psql -X -q -v ON_ERROR_STOP=1)

declare -A BASE=(
    [catalogo]=db_catalogo
    [identidad]=db_identidad
    [compras]=db_compras
    [inventarios]=db_inventario
    [ventas]=db_ventas
    [reportes]=db_reportes
)
OPERATIVOS=(catalogo identidad compras inventarios ventas)

paso() { printf '\n== %s\n' "$*"; }
sql() { "${PSQL[@]}" -d "$1" -f "$2"; }

paso "Crear bases (la instancia debe estar vacía)"
for esquema in catalogo identidad compras inventarios ventas reportes; do
    "${PSQL[@]}" -d postgres -c "CREATE DATABASE ${BASE[$esquema]}"
done

paso "Roles de grupo"
sql postgres sql/permisos/01_roles.sql

paso "Esquemas y tablas"
for esquema in catalogo identidad compras inventarios ventas reportes; do
    sql "${BASE[$esquema]}" "sql/esquemas/$esquema.sql"
done

paso "Datos sintéticos y casos de prueba"
for esquema in "${OPERATIVOS[@]}"; do
    sql "${BASE[$esquema]}" "sql/datos/$esquema.sql"
done
sql db_catalogo sql/datos/casos_catalogo.sql
sql db_inventario sql/datos/casos_inventarios.sql
sql db_ventas sql/datos/casos_ventas.sql
for esquema in "${OPERATIVOS[@]}"; do
    sql "${BASE[$esquema]}" sql/datos/ajustar_secuencias.sql
done

paso "Permisos por esquema"
for esquema in "${OPERATIVOS[@]}"; do
    sql "${BASE[$esquema]}" "sql/permisos/$esquema.sql"
done

paso "Cuenta lectora de Reportes"
for esquema in "${OPERATIVOS[@]}"; do
    "${PSQL[@]}" -d "${BASE[$esquema]}" -v esquema="$esquema" -f sql/reportes/00_lector_origen.psql
done
echo "ALTER ROLE distribured_reportes PASSWORD :'clave';" |
    "${PSQL[@]}" -d postgres -v clave="$REPORTES_CLAVE"

paso "Fuentes externas, vistas y permisos de Reportes"
"${PSQL[@]}" -d db_reportes \
    -v host_catalogo="$HOST_FDW" -v host_compras="$HOST_FDW" -v host_inventario="$HOST_FDW" \
    -v host_identidad="$HOST_FDW" -v host_ventas="$HOST_FDW" \
    -v clave_catalogo="$REPORTES_CLAVE" -v clave_compras="$REPORTES_CLAVE" \
    -v clave_inventario="$REPORTES_CLAVE" -v clave_identidad="$REPORTES_CLAVE" \
    -v clave_ventas="$REPORTES_CLAVE" \
    -f sql/reportes/01_fuentes.psql
sql db_reportes sql/reportes/02_vistas.sql
sql db_reportes sql/permisos/reportes.sql

paso "Pruebas"
sql db_catalogo sql/pruebas/catalogo.sql
sql db_compras sql/pruebas/integridad_compras.sql
sql db_inventario sql/pruebas/inventarios.sql
sql db_inventario sql/pruebas/roles_inventario.sql
sql db_ventas sql/pruebas/integridad_ventas.sql
sql db_ventas sql/pruebas/fragmentos_ventas.sql
sql db_reportes sql/pruebas/referencias_distribuidas.sql
sql db_reportes sql/pruebas/reportes.sql
sql db_reportes sql/pruebas/rol_gerencia_reportes.sql

paso "Aserciones sobre los resultados de las pruebas"
sql postgres sql/pruebas/afirmaciones.sql

paso "Consultas obligatorias"
sql db_reportes sql/reportes/20_consultas.sql

echo
echo "Instalación y pruebas SQL completadas."
