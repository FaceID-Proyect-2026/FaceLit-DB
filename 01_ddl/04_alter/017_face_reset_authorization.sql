ALTER TABLE facialrecognition.face_reset_request
    ADD COLUMN authorization_token UUID,
    ADD COLUMN authorization_expires_at TIMESTAMPTZ,
    ADD COLUMN consumed_at TIMESTAMPTZ,
    ADD COLUMN context_json TEXT,
    ADD COLUMN request_notified BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN decision_notified BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN completion_notified BOOLEAN NOT NULL DEFAULT FALSE;
