ALTER TABLE environment.environment
    ADD COLUMN IF NOT EXISTS capacity INTEGER,
    ADD COLUMN IF NOT EXISTS state VARCHAR(20) NOT NULL DEFAULT 'ACTIVE';

ALTER TABLE environment.environment
    ADD CONSTRAINT chk_environment_state CHECK (state IN ('ACTIVE', 'INACTIVE'));

ALTER TABLE environment.environment
    ADD CONSTRAINT chk_environment_capacity CHECK (capacity IS NULL OR capacity > 0);

CREATE UNIQUE INDEX IF NOT EXISTS uq_environment_name_normalized
ON environment.environment (lower(btrim(environment_name)));
