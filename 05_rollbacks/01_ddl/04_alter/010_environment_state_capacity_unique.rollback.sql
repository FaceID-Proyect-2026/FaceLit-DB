DROP INDEX IF EXISTS environment.uq_environment_name_normalized;

ALTER TABLE environment.environment
    DROP CONSTRAINT IF EXISTS chk_environment_capacity;

ALTER TABLE environment.environment
    DROP CONSTRAINT IF EXISTS chk_environment_state;

ALTER TABLE environment.environment
    DROP COLUMN IF EXISTS state;

ALTER TABLE environment.environment
    DROP COLUMN IF EXISTS capacity;
