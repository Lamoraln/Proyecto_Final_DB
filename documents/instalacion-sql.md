# Instalación y verificación de DistribuRed

## Bases y orden de ejecución

Conéctese mediante psql o pgAdmin a la instancia propietaria de cada esquema. En
Neon use el endpoint directo. Los archivos `.psql` requieren psql. Los `.sql`
pueden ejecutarse en el Query Tool de pgAdmin. En psql use `-v ON_ERROR_STOP=1`.

| Base | Esquema | Script de creación |
|---|---|---|
| db_catalogo | catalogo | sql/esquemas/catalogo.sql |
| db_identidad | identidad | sql/esquemas/identidad.sql |
| db_compras | compras | sql/esquemas/compras.sql |
| db_inventario | inventarios | sql/esquemas/inventarios.sql |
| db_ventas | ventas | sql/esquemas/ventas.sql |
| db_reportes | reportes | sql/esquemas/reportes.sql |

1. **Instalación limpia.** Cree las bases si hacen falta y ejecute sus DDL. Los
   DDL de Inventarios y Ventas ya incluyen las cuatro particiones por ID de sede.
2. **Datos sintéticos.** En una instalación vacía, ejecute `sql/datos/<esquema>.sql`
   en orden Catálogo, Identidad, Compras, Inventarios y Ventas. Aplique
   `casos_catalogo.sql`, `casos_inventarios.sql` y `casos_ventas.sql` en sus
   respectivas bases. Ejecute `ajustar_secuencias.sql` en cada base operativa
   después de la carga. Los usuarios sintéticos se usan en el modelo de datos.
3. **Permisos.** Ejecute `sql/permisos/01_roles.sql` y el script correspondiente al
   esquema en cada instancia. Los grupos `NOLOGIN` se asignan a cuentas reales
   con `GRANT rol_auditor TO cuenta_consulta`, por ejemplo. Para administrar
   objetos y cuentas del proyecto Neon se usa la cuenta administradora de la
   instancia. Las pruebas de roles asumen que esa cuenta puede hacer `SET ROLE`.
4. **Lectores remotos.** Ejecute `sql/reportes/00_lector_origen.psql` en las cinco
   bases operativas pasando `-v esquema=catalogo` o el esquema correspondiente.
   En cada una asigne una contraseña distinta mediante `\password distribured_reportes`.
5. **Reportes.** En db_reportes, cargue las variables
   `host_catalogo`, `host_identidad`, `host_compras`, `host_inventario` y
   `host_ventas` en una sesión psql privada. Cargue las contraseñas en las
   variables `clave_<servicio>` correspondientes. Puede usar
   `\getenv clave_catalogo DISTRIBURED_CLAVE_CATALOGO` tras inyectar la variable
   de entorno de forma local. Ejecute `\i sql/reportes/01_fuentes.psql`.
   Con la misma cuenta propietaria ejecute `02_vistas.sql` y el script
   `sql/permisos/reportes.sql`.
6. **Pruebas y consultas.** Ejecute los archivos de `sql/pruebas` en las bases
   indicadas en sus nombres y `20_consultas.sql` en db_reportes. Las consultas que
   definen cortes usan fechas explícitas de 2026 para repetir la demostración.

## Migración de bases cargadas

En instancias con datos use `sql/migraciones/particionar_inventarios.sql` y
`particionar_ventas.sql` si sus tablas aún son ordinarias. Pruébelas primero
en ramas separadas. Los scripts copian y cotejan las filas bajo un bloqueo,
conservan los permisos de la tabla, redirigen las FK locales y guardan la tabla
original en el esquema privado `respaldo_distribured`. Las tablas de respaldo
quedan fuera de las consultas, vistas y cargas de la aplicación.
