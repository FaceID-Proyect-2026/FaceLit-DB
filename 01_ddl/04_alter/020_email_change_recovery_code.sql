-- Nullable additions preserve all existing recovery history and ordinary recovery codes.
ALTER TABLE security.password_recovery
    ADD COLUMN access_request_id uuid REFERENCES security.account_access_request(id),
    ADD COLUMN verified_at timestamptz;
CREATE INDEX idx_password_recovery_access_request ON security.password_recovery(access_request_id);
