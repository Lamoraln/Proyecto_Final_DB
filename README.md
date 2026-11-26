# DistribuRed

DistribuRed reúne catálogo, compras, inventarios, ventas, identidad y reportes.
Cada servicio se ejecuta en un proceso propio y consulta su instancia PostgreSQL.
La web usa una pasarela local para acceder a las seis API desde el mismo origen.

## Arranque de la aplicación

Requiere Python 3.10 o superior y una base configurada por servicio. El
[manual de la aplicación](documents/instalacion-app.md) describe la configuración
inicial, las cuentas PostgreSQL y cómo establecer una contraseña web.

En Windows, con el entorno virtual activo, ejecuta desde la raíz:

```powershell
python -m pip install -r requirements.txt
python configurar_identidad.py claves
python arrancar.py
```

Abre <http://127.0.0.1:8000/login.html>. Tras la configuración inicial,
`python arrancar.py` basta para levantar todos los servicios. También puedes
arrancar uno solo, por ejemplo `python arrancar.py inventarios`.

## Entrega de Bases de Datos

La entrega SQL utiliza seis instancias PostgreSQL (una por microservicio) y cuatro sedes
dentro de Catálogo, incluyendo el centro de distribución. El enunciado requiere
implementar y verificar la capa de datos. Las pantallas web y las API locales son
una extensión del proyecto.

- [Instalación y orden de scripts](documents/instalacion-sql.md)
- [Arquitectura, modelo y permisos](documents/arquitectura-datos.md)
- [Evidencias de las pruebas](documents/evidencias-sql.md)
- [Consultas obligatorias](sql/reportes/20_consultas.sql)
