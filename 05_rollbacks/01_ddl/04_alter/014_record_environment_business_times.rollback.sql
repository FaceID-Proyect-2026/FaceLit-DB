ALTER TABLE environment.record_environment
DROP CONSTRAINT IF EXISTS chk_record_environment_times;

ALTER TABLE environment.record_environment
DROP CONSTRAINT IF EXISTS chk_record_environment_registration_minutes;

ALTER TABLE environment.record_environment
ALTER COLUMN exit_time DROP NOT NULL;

ALTER TABLE environment.record_environment
ALTER COLUMN shutdown_time DROP NOT NULL;

ALTER TABLE environment.record_environment
ALTER COLUMN exit_time TYPE TIME
USING exit_time::time;

ALTER TABLE environment.record_environment
ALTER COLUMN shutdown_time TYPE TIME
USING shutdown_time::time;

ALTER TABLE environment.record_environment
DROP COLUMN IF EXISTS entry_time;

ALTER TABLE environment.record_environment
ADD CONSTRAINT chk_record_environment_times CHECK (
    (exit_time IS NULL AND shutdown_time IS NULL)
    OR (
        exit_time IS NOT NULL
        AND shutdown_time IS NOT NULL
        AND shutdown_time > exit_time
    )
);

DROP INDEX IF EXISTS environment.idx_record_environment_session;

CREATE INDEX IF NOT EXISTS idx_record_environment_session
ON environment.record_environment (id_chip, created_at);
