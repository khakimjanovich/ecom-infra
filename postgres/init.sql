-- One database, one schema and one user per module.
-- Each user owns only its own schema, so it cannot read or write another module's tables.
DO $$
DECLARE m text;
BEGIN
  FOREACH m IN ARRAY ARRAY['partner', 'commission', 'epos', 'card', 'payment', 'bin'] LOOP
    EXECUTE format('CREATE USER %I WITH PASSWORD %L', m || '_user', 'local-only');
    EXECUTE format('CREATE SCHEMA %I AUTHORIZATION %I', m, m || '_user');
    EXECUTE format('ALTER ROLE %I SET search_path = %I', m || '_user', m);
  END LOOP;
END $$;
REVOKE ALL ON SCHEMA public FROM PUBLIC;
-- The commission module keeps fee rules from overlapping with an exclusion constraint on uuid, text
-- and time ranges together, which needs btree_gist. Extensions need a superuser, so it is added here.
CREATE EXTENSION IF NOT EXISTS btree_gist SCHEMA commission;

-- A person checking the data: ecom_viewer reads every module's schema and writes nothing. Tables
-- the modules create later are readable too (default privileges per owner).
CREATE USER ecom_viewer WITH PASSWORD 'local-only';
DO $$
DECLARE m text;
BEGIN
  FOREACH m IN ARRAY ARRAY['partner', 'commission', 'epos', 'card', 'payment', 'bin'] LOOP
    EXECUTE format('GRANT USAGE ON SCHEMA %I TO ecom_viewer', m);
    EXECUTE format('GRANT SELECT ON ALL TABLES IN SCHEMA %I TO ecom_viewer', m);
    EXECUTE format('ALTER DEFAULT PRIVILEGES FOR ROLE %I IN SCHEMA %I GRANT SELECT ON TABLES TO ecom_viewer', m || '_user', m);
  END LOOP;
END $$;
ALTER ROLE ecom_viewer SET search_path = partner, commission, epos, card, payment, bin;
