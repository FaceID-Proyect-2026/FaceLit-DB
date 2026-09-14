ALTER TABLE security.user_chip DROP CONSTRAINT IF EXISTS fk_user_chip_chip;
ALTER TABLE security.user_chip DROP CONSTRAINT IF EXISTS fk_user_chip_user;
ALTER TABLE security.user_configuration DROP CONSTRAINT IF EXISTS fk_user_configuration_user;
ALTER TABLE security.user_session DROP CONSTRAINT IF EXISTS fk_user_session_user;
ALTER TABLE security.password_recovery DROP CONSTRAINT IF EXISTS fk_password_recovery_user;
ALTER TABLE security.credential DROP CONSTRAINT IF EXISTS fk_credential_user;
