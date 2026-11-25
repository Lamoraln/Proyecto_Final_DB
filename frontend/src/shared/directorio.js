export function montarDirectorio(contenedor, vistas, etiquetaSelector = 'Consulta') {
  const filtros = document.createElement('div');
  filtros.className = 'filters';

  const selector = document.createElement('select');
  const etiquetaVista = document.createElement('label');
  etiquetaVista.append(etiquetaSelector, selector);

  for (const [indice, vista] of vistas.entries()) {
    selector.add(new Option(vista.titulo, String(indice)));
  }

  const buscar = document.createElement('input');
  buscar.type = 'search';
  buscar.placeholder = 'Escribe para buscar';

  const etiquetaBusqueda = document.createElement('label');
  etiquetaBusqueda.className = 'search';
  etiquetaBusqueda.append('Buscar en la tabla', buscar);
  filtros.append(etiquetaVista, etiquetaBusqueda);

  const conteo = document.createElement('p');
  conteo.className = 'directorio-conteo';
  conteo.setAttribute('role', 'status');

  const envoltura = document.createElement('div');
  envoltura.className = 'table-wrap';
  envoltura.tabIndex = 0;
  envoltura.setAttribute('role', 'region');

  const tabla = document.createElement('table');
  const encabezado = tabla.createTHead();
  const cuerpo = tabla.createTBody();
  envoltura.append(tabla);

  function normalizar(valor) {
    return String(valor ?? '')
      .toLocaleLowerCase('es-CO')
      .normalize('NFD')
      .replace(/\p{Diacritic}/gu, '')
      .trim();
  }

  function renderizar() {
    const vista = vistas[Number(selector.value)];
    const termino = normalizar(buscar.value);
    const filas = vista.filas.filter(fila =>
      normalizar(fila.join(' ')).includes(termino),
    );

    envoltura.setAttribute('aria-label', vista.titulo);
    conteo.textContent = `${filas.length} de ${vista.filas.length} registros`;

    encabezado.replaceChildren();
    const cabecera = encabezado.insertRow();

    for (const nombre of vista.columnas) {
      const celda = document.createElement('th');
      celda.scope = 'col';
      celda.textContent = nombre;
      cabecera.append(celda);
    }

    cuerpo.replaceChildren();

    if (filas.length === 0) {
      const celda = cuerpo.insertRow().insertCell();
      celda.colSpan = vista.columnas.length;
      celda.className = 'empty';
      celda.textContent = 'No hay registros para esta consulta.';
      return;
    }

    for (const registro of filas) {
      const fila = cuerpo.insertRow();

      for (const [indice, valor] of registro.entries()) {
        const celda = document.createElement(indice === 0 ? 'th' : 'td');
        if (indice === 0) celda.scope = 'row';
        if (typeof valor === 'number') celda.className = 'number';
        celda.textContent = valor ?? '—';
        fila.append(celda);
      }
    }
  }

  selector.addEventListener('change', () => {
    buscar.value = '';
    renderizar();
  });
  buscar.addEventListener('input', renderizar);

  contenedor.replaceChildren(filtros, conteo, envoltura);
  renderizar();
}

export function mostrarErrorConsulta(contenedor, error) {
  console.error('Error al cargar la consulta', error);
  const mensaje = document.createElement('p');
  mensaje.className = 'empty';
  mensaje.setAttribute('role', 'alert');
  mensaje.textContent = 'No se pudo cargar la consulta.';
  contenedor.replaceChildren(mensaje);
}