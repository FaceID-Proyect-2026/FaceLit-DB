DROP INDEX IF EXISTS security.idx_password_recovery_access_request;
ALTER TABLE security.password_recovery DROP COLUMN access_request_id, DROP COLUMN verified_at;
