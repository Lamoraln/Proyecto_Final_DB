-- Usar una cuenta que ya tenga membresía con SET habilitado.
DO $pruebas$
DECLARE filas bigint;
BEGIN
  BEGIN
    SET LOCAL ROLE rol_gerencia;
    SELECT count(*) INTO filas FROM reportes.vista_reporte_corporativo;
    IF filas <> 4 THEN RAISE EXCEPTION 'No hay datos de prueba: %', filas; END IF;
    RESET ROLE;
    RAISE EXCEPTION USING ERRCODE='ZX001', MESSAGE='Pruebas aprobadas';
  EXCEPTION WHEN SQLSTATE 'ZX001' THEN
    RAISE NOTICE 'Gerencia puede consultar el consolidado.';
  END;
END
$pruebas$;
