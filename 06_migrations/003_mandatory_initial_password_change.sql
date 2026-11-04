ALTER TABLE security.user_app
    ADD COLUMN IF NOT EXISTS initial_password_changed BOOLEAN NOT NULL DEFAULT FALSE;

-- Existing accounts must complete the one-time change before using the system.
UPDATE security.user_app
SET initial_password_changed = FALSE
WHERE initial_password_changed IS DISTINCT FROM FALSE;
