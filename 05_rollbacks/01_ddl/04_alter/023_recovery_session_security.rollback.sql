DROP TABLE security.auth_rate_limit;
DROP INDEX security.idx_recovery_account_latest;
ALTER TABLE security.password_recovery DROP CONSTRAINT chk_recovery_attempts,
    DROP COLUMN reset_token_hash, DROP COLUMN verification_attempts, DROP COLUMN destination_email;
-- Previously consumed recovery codes stay consumed: rollback must not reactivate them.
