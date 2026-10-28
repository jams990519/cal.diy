-- Borra los índices inválidos que deja un CREATE INDEX CONCURRENTLY interrumpido,
-- para que la migración pueda volver a crearlos (usan IF NOT EXISTS).
DO $$
DECLARE r record;
BEGIN
  FOR r IN
    SELECT n.nspname, c.relname
    FROM pg_index i
    JOIN pg_class c ON c.oid = i.indexrelid
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE NOT i.indisvalid AND n.nspname = 'public'
  LOOP
    EXECUTE format('DROP INDEX %I.%I', r.nspname, r.relname);
  END LOOP;
END $$;
