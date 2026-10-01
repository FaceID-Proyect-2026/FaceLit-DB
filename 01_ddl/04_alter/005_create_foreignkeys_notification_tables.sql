ALTER TABLE notification.notification ADD CONSTRAINT fk_notification_user FOREIGN KEY (id_user_app) REFERENCES security.user_app(id_user_app);
ALTER TABLE notification.email_log ADD CONSTRAINT fk_email_log_notification FOREIGN KEY (id_notification) REFERENCES notification.notification(id_notification);
