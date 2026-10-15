ALTER TABLE facialrecognition.face_reset_request
    DROP COLUMN completion_notified,
    DROP COLUMN decision_notified,
    DROP COLUMN request_notified,
    DROP COLUMN context_json,
    DROP COLUMN consumed_at,
    DROP COLUMN authorization_expires_at,
    DROP COLUMN authorization_token;
