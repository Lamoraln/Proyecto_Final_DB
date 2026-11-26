-- Usar una cuenta que ya tenga membresía con SET habilitado.
DO $pruebas$
DECLARE filas bigint;
BEGIN
  BEGIN
    SET LOCAL ROLE rol_resp_inventario;
    SELECT count(*) INTO filas FROM inventarios.inventarios;
    IF filas < 1 THEN RAISE EXCEPTION 'No hay datos de prueba: %', filas; END IF;
    UPDATE inventarios.inventarios SET existencia_actual=existencia_actual WHERE false;
    RESET ROLE;
    SET LOCAL ROLE rol_gerencia;
    SELECT count(*) INTO filas FROM inventarios.inventarios;
    IF filas < 1 THEN RAISE EXCEPTION 'No hay datos de prueba: %', filas; END IF;
    BEGIN
      UPDATE inventarios.inventarios SET existencia_actual=existencia_actual WHERE false;
      RAISE EXCEPTION 'UPDATE permitido inesperadamente';
    EXCEPTION WHEN insufficient_privilege THEN NULL;
    END;
    BEGIN
      DELETE FROM inventarios.inventarios WHERE false;
      RAISE EXCEPTION 'DELETE permitido inesperadamente';
    EXCEPTION WHEN insufficient_privilege THEN NULL;
    END;
    RESET ROLE;
    RAISE EXCEPTION USING ERRCODE='ZX001', MESSAGE='Pruebas aprobadas';
  EXCEPTION WHEN SQLSTATE 'ZX001' THEN
    RAISE NOTICE 'SELECT y UPDATE autorizados según el rol; UPDATE y DELETE rechazados para Gerencia.';
  END;
END
$pruebas$;
