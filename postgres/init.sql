-- One database, one schema per module (episode 02).
-- The app connects as acquiring_app, which owns the module schemas.
CREATE USER acquiring_app WITH PASSWORD 'local-only';
CREATE SCHEMA partner AUTHORIZATION acquiring_app;
CREATE SCHEMA commission AUTHORIZATION acquiring_app;
CREATE SCHEMA terminal AUTHORIZATION acquiring_app;
CREATE SCHEMA card AUTHORIZATION acquiring_app;
CREATE SCHEMA payment AUTHORIZATION acquiring_app;
