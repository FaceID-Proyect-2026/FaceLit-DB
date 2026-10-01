ALTER TABLE notification.notification
    ADD COLUMN IF NOT EXISTS notification_type VARCHAR(60) NOT NULL DEFAULT 'academic_delete_blocked';

ALTER TABLE notification.notification
    ADD COLUMN IF NOT EXISTS title VARCHAR(120) NOT NULL DEFAULT 'Notificacion';

ALTER TABLE notification.notification
    ADD COLUMN IF NOT EXISTS metadata_json TEXT;
