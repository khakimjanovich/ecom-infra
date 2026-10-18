-- One database, one schema per module, one user per module (episode 02).
-- Each user owns only its own schema, so it cannot read or write another module's tables.
DO $$
DECLARE m text;
BEGIN
  FOREACH m IN ARRAY ARRAY['partner', 'commission', 'terminal', 'card', 'payment'] LOOP
    EXECUTE format('CREATE USER %I WITH PASSWORD %L', m || '_user', 'local-only');
    EXECUTE format('CREATE SCHEMA %I AUTHORIZATION %I', m, m || '_user');
    EXECUTE format('ALTER ROLE %I SET search_path = %I', m || '_user', m);
  END LOOP;
END $$;
REVOKE ALL ON SCHEMA public FROM PUBLIC;
