ALTER TABLE environment.record_environment
DROP CONSTRAINT IF EXISTS chk_record_environment_times;

ALTER TABLE environment.record_environment
ADD COLUMN IF NOT EXISTS entry_time TIMESTAMPTZ;

UPDATE environment.record_environment
SET entry_time = created_at
WHERE entry_time IS NULL;

ALTER TABLE environment.record_environment
ALTER COLUMN entry_time SET NOT NULL;

ALTER TABLE environment.record_environment
ALTER COLUMN registration_minutes SET NOT NULL;

ALTER TABLE environment.record_environment
DROP CONSTRAINT IF EXISTS chk_record_environment_registration_minutes;

ALTER TABLE environment.record_environment
ADD CONSTRAINT chk_record_environment_registration_minutes
CHECK (registration_minutes > 0);

DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'environment'
          AND table_name = 'record_environment'
          AND column_name = 'exit_time'
          AND data_type = 'time without time zone'
    ) THEN
        ALTER TABLE environment.record_environment
        ALTER COLUMN exit_time TYPE TIMESTAMPTZ
        USING CASE
            WHEN exit_time IS NULL THEN NULL
            ELSE (created_at::date + exit_time)::timestamptz
        END;
    END IF;
END $$;

DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'environment'
          AND table_name = 'record_environment'
          AND column_name = 'shutdown_time'
          AND data_type = 'time without time zone'
    ) THEN
        ALTER TABLE environment.record_environment
        ALTER COLUMN shutdown_time TYPE TIMESTAMPTZ
        USING CASE
            WHEN shutdown_time IS NULL THEN NULL
            ELSE (created_at::date + shutdown_time)::timestamptz
        END;
    END IF;
END $$;

ALTER TABLE environment.record_environment
ALTER COLUMN exit_time SET NOT NULL;

ALTER TABLE environment.record_environment
ALTER COLUMN shutdown_time SET NOT NULL;

ALTER TABLE environment.record_environment
ADD CONSTRAINT chk_record_environment_times CHECK (
    exit_time > entry_time
    AND shutdown_time > exit_time
);

DROP INDEX IF EXISTS environment.idx_record_environment_session;

CREATE INDEX IF NOT EXISTS idx_record_environment_session
ON environment.record_environment (id_chip, entry_time);
