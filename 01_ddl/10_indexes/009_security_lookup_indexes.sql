CREATE INDEX IF NOT EXISTS idx_user_session_user ON security.user_session (id_user_app);
CREATE INDEX IF NOT EXISTS idx_credential_user ON security.credential (id_user_app);
CREATE INDEX IF NOT EXISTS idx_password_recovery_token ON security.password_recovery (token);
