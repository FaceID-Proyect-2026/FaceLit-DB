CREATE INDEX idx_notification_user_unread ON notification.notification (id_user_app) WHERE read_status = FALSE;
