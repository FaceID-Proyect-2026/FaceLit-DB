ALTER TABLE security.password_recovery
    ADD COLUMN destination_email VARCHAR(255),
    ADD COLUMN verification_attempts INTEGER NOT NULL DEFAULT 0,
    ADD COLUMN reset_token_hash VARCHAR(64),
    ADD CONSTRAINT chk_recovery_attempts CHECK (verification_attempts >= 0);
UPDATE security.password_recovery SET used = TRUE WHERE used = FALSE;
CREATE INDEX idx_recovery_account_latest ON security.password_recovery (id_user_app, created_at DESC) WHERE used = FALSE;
CREATE TABLE security.auth_rate_limit (
    bucket_key VARCHAR(64) PRIMARY KEY,
    window_start TIMESTAMPTZ NOT NULL,
    attempts INTEGER NOT NULL CHECK (attempts >= 0)
);
