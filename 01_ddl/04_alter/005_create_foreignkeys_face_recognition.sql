ALTER TABLE facialrecognition.user_face ADD CONSTRAINT fk_user_face_user FOREIGN KEY (id_user_app) REFERENCES security.user_app(id_user_app);
ALTER TABLE facialrecognition.facial_event ADD CONSTRAINT fk_facial_event_user FOREIGN KEY (id_user_app) REFERENCES security.user_app(id_user_app);
ALTER TABLE facialrecognition.facial_event ADD CONSTRAINT fk_facial_event_record_environment FOREIGN KEY (id_record_environment) REFERENCES environment.record_environment(id_record_environment);
ALTER TABLE facialrecognition.facial_event ADD CONSTRAINT fk_facial_event_device FOREIGN KEY (id_device) REFERENCES facialrecognition.device(id_device);
ALTER TABLE facialrecognition.face_reset_request ADD CONSTRAINT fk_face_reset_request_user FOREIGN KEY (id_user_app) REFERENCES security.user_app(id_user_app);
ALTER TABLE facialrecognition.face_reset_request ADD CONSTRAINT fk_face_reset_request_resolver FOREIGN KEY (resolved_by) REFERENCES security.user_app(id_user_app);
ALTER TABLE facialrecognition.biometric_log ADD CONSTRAINT fk_biometric_log_event FOREIGN KEY (id_facial_event) REFERENCES facialrecognition.facial_event(id_facial_event);
