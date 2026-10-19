-- One database, one schema and one user per module, and per service that keeps data (bin).
-- Each user owns only its own schema, so it cannot read or write another module's tables.
DO $$
DECLARE m text;
BEGIN
  FOREACH m IN ARRAY ARRAY['partner', 'commission', 'terminal', 'card', 'payment', 'bin'] LOOP
    EXECUTE format('CREATE USER %I WITH PASSWORD %L', m || '_user', 'local-only');
    EXECUTE format('CREATE SCHEMA %I AUTHORIZATION %I', m, m || '_user');
    EXECUTE format('ALTER ROLE %I SET search_path = %I', m || '_user', m);
  END LOOP;
END $$;
REVOKE ALL ON SCHEMA public FROM PUBLIC;
-- The commission module keeps fee rules from overlapping with an exclusion constraint on uuid, text
-- and time ranges together, which needs btree_gist. Extensions need a superuser, so it is added here.
CREATE EXTENSION IF NOT EXISTS btree_gist SCHEMA commission;
