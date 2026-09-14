ALTER TABLE notification.notification ADD CONSTRAINT fk_notification_user FOREIGN KEY (id_user_app) REFERENCES security.user_app(id_user_app);
ALTER TABLE notification.notification ADD CONSTRAINT fk_notification_event FOREIGN KEY (id_facial_event) REFERENCES facialrecognition.facial_event(id_facial_event);
ALTER TABLE notification.email_log ADD CONSTRAINT fk_email_log_notification FOREIGN KEY (id_notification) REFERENCES notification.notification(id_notification);
