# Instalación de la aplicación DistribuRed

## Configuración inicial

1. Crea y activa un entorno virtual en la raíz del proyecto. En Windows, si ya
   tienes `venv`, usa `.\venv\Scripts\python.exe` como intérprete de los comandos.
   Instala las dependencias con `python -m pip install -r requirements.txt`.
2. Copia cada `services/<carpeta>/.env` a `.env` dentro de su propia
   carpeta y completa `DB_HOST`, `DB_USER` y `DB_PASSWORD` con los de la
   instancia correspondiente. Si conservaste `.env` de Catálogo e Inventarios,
   mantenlos y completa las demás conexiones. En Neon usa SSL y el host de
   cada proyecto. La instalación de tablas y reportes se documenta en
   [Instalación SQL](instalacion-sql.md).
3. Usa cuentas de conexión PostgreSQL dedicadas. Si una cuenta ya tiene
   permisos suficientes, reutilízala. Si falta, créala con `CREATE ROLE nombre LOGIN`
   en la instancia correspondiente y asigna su clave con `\password nombre`
   en psql. Ejecuta `sql/permisos/cuentas_aplicacion.psql` en esa instancia
   con `-v cuenta=nombre -v servicio=<servicio>` y `-v ON_ERROR_STOP=1`.
   Los valores para servicio aparecen en la primera columna de la tabla
   inferior. Si deseas habilitar el cambio del mínimo, ejecuta también
   `sql/permisos/editar_minimo.psql` en Inventarios y añade
   `INVENTARIO_ESCRITURA=1` al `.env` de ese servicio.
4. Ejecuta `python configurar_identidad.py claves` una vez. La clave privada
   firma sesiones en Identidad. Los demás servicios verifican la firma con la
   pública. Las claves se guardan en `.claves/`. En ejecuciones aisladas
   se puede suministrar `JWT_PRIVATE_KEY_FILE` a Identidad y
   `JWT_PUBLIC_KEY_FILE` a los verificadores.
5. En `db_identidad`, identifica un usuario de aplicación que esté activo:

   ```sql
   SELECT u.nombre_usuario, u.rol, u.estado, e.id_sede, e.estado AS estado_empleado
   FROM identidad.usuarios u JOIN identidad.empleados e USING (id_empleado)
   ORDER BY u.rol, u.nombre_usuario;
   ```

   Ejecuta `python configurar_identidad.py contrasena NOMBRE_USUARIO` para
   asignar su contraseña web. El programa pide las contraseñas sin mostrarlas.
   Repite para cada cuenta de la demostración. Los hashes sintéticos de carga
   no permiten iniciar sesión hasta completar este paso.

## Arrancar y comprobar

Ejecuta `python arrancar.py` y visita
<http://127.0.0.1:8000/login.html>. Desde ese momento el navegador llama a la
pasarela en el puerto 8000. Cada servicio abre su propia conexión con PostgreSQL.

| Servicio para `arrancar.py` | Carpeta en services | Puerto | Base |
|---|---|---:|---|
| web | — | 8000 | — |
| catalogo | catalogo-service | 8001 | db_catalogo |
| inventarios | inventario-service | 8002 | db_inventario |
| identidad | identidad-service | 8003 | db_identidad |
| compras | compras-service | 8004 | db_compras |
| ventas | ventas-service | 8005 | db_ventas |
| reportes | reportes-service | 8006 | db_reportes |

Cada API expone `/salud` en su puerto para comprobar su base. Puedes usar
`python arrancar.py <servicio>` en terminales separadas y detener cada proceso
con Ctrl+C. Para la prueba de independencia, detén Catálogo después del login.
Ventas e Inventarios siguen devolviendo sus datos operativos y la interfaz
puede mostrar IDs cuando faltan nombres. Compras y Transferencias requieren
Catálogo para confirmar almacenes de perfiles restringidos. Si Catálogo no
responde, esas solicitudes se cierran con un error de disponibilidad.
Reportes consulta su instancia y depende de la disponibilidad de las bases
remotas de PostgreSQL que utilizan sus vistas. Puede funcionar con las API
operativas apagadas.

## Permisos y alcance de la web

- Los permisos académicos de PostgreSQL se prueban con los roles de
  [la matriz SQL](arquitectura-datos.md). La web obtiene el rol y la sede de
  Identidad, y cada API valida la firma y aplica su política antes de consultar.
  Las conexiones de aplicación usan cuentas PostgreSQL dedicadas.
- Una consulta sin credenciales responde `401`. Con un rol o sede fuera
  de su alcance responde `403`. Los cambios de mínimo aplican únicamente a
  registros existentes y están deshabilitados por defecto.
- Las pantallas consultan datos reales. Reportes permite explorar las diez
  vistas obligatorias. La carga o modificación de compras, ventas,
  transferencias y devoluciones se realiza con la capa SQL del proyecto.
- La aplicación se ejecuta en loopback para la demostración. Los tokens
  duran 30 minutos y caducan por tiempo. Cerrar sesión limpia el navegador.
  Cambios de rol y desactivaciones se reflejan en un nuevo inicio de sesión.

## Verificación de esta versión

La prueba integral levantó la pasarela y las seis API con seis bases de prueba
en PostgreSQL local. Reportes usó postgres_fdw para consultar las otras
bases. Se verificaron los seis perfiles, los códigos 401 y 403, el filtro por
sede del vendedor y la actualización del mínimo con una cuenta operativa.
Las ocho pantallas se abrieron en Chromium y el selector de Reportes consultó
una vista real. También se consultaron las diez vistas mediante la API.

Al detener Catálogo, Inventarios, Ventas y Reportes siguieron devolviendo los
datos probados. Compras devolvió 503 para un responsable cuyo alcance requería
confirmar almacenes. Al detener Identidad, Inventarios siguió aceptando un
token válido ya emitido. La comprobación de la aplicación se realizó con
datos sintéticos y cuentas locales de prueba.
