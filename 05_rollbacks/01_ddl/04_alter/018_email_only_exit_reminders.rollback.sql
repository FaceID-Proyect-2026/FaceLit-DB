UPDATE notification.notification SET channel = 'APP_EMAIL' WHERE channel = 'EMAIL';
UPDATE notification.email_log SET send_status = 'FAILED' WHERE send_status = 'CANCELLED';
ALTER TABLE notification.notification DROP CONSTRAINT notification_channel_check;
ALTER TABLE notification.notification ADD CONSTRAINT notification_channel_check CHECK (channel IN ('APP', 'APP_EMAIL'));
ALTER TABLE notification.email_log DROP CONSTRAINT email_log_send_status_check;
ALTER TABLE notification.email_log ADD CONSTRAINT email_log_send_status_check CHECK (send_status IN ('PENDING', 'SENT', 'FAILED'));
