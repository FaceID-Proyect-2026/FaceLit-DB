ALTER TABLE security.user_app
    ADD COLUMN IF NOT EXISTS initial_password_prompt_seen BOOLEAN NOT NULL DEFAULT FALSE;

UPDATE security.user_app u
SET initial_password_prompt_seen = TRUE
WHERE EXISTS (
    SELECT 1
    FROM security.user_session s
    WHERE s.id_user_app = u.id_user_app
);
