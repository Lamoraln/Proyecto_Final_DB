# Proyecto_Final_DB
En este repositorio se va a desarrollar el sistema para el desarrollo del proyecto final de bases de datos


## Abrir el frontend de DistribuRed

Sirve la carpeta `frontend` por HTTP. En Windows, puedes abrir el proyecto
en VS Code y usar **Open with Live Server** sobre `frontend/login.html`.
Esta opción no requiere Python.

Si tienes Python instalado, también puedes ejecutar desde la raíz del repositorio:

```powershell
py -m http.server 8000 --bind 127.0.0.1 --directory frontend
```

Luego abre [http://127.0.0.1:8000/login.html](http://127.0.0.1:8000/login.html).
Abre la página por HTTP para que el navegador cargue los módulos de JavaScript.
Los archivos del frontend ya están listos para servir.

El selector ofrece seis perfiles de demostración. La sesión se guarda en la
pestaña del navegador y los registros provienen de datos de ejemplo incluidos
en JavaScript. Para autenticar usuarios reales y aplicar permisos de PostgreSQL
hace falta una API que verifique esos permisos del lado del servidor.
