ALTER TABLE notification.email_log DROP CONSTRAINT IF EXISTS fk_email_log_notification;
ALTER TABLE notification.notification DROP CONSTRAINT IF EXISTS fk_notification_event;
ALTER TABLE notification.notification DROP CONSTRAINT IF EXISTS fk_notification_user;
