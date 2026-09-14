ALTER TABLE security.credential ADD CONSTRAINT fk_credential_user FOREIGN KEY (id_user_app) REFERENCES security.user_app(id_user_app);
ALTER TABLE security.password_recovery ADD CONSTRAINT fk_password_recovery_user FOREIGN KEY (id_user_app) REFERENCES security.user_app(id_user_app);
ALTER TABLE security.user_session ADD CONSTRAINT fk_user_session_user FOREIGN KEY (id_user_app) REFERENCES security.user_app(id_user_app);
ALTER TABLE security.user_configuration ADD CONSTRAINT fk_user_configuration_user FOREIGN KEY (id_user_app) REFERENCES security.user_app(id_user_app);
ALTER TABLE security.user_chip ADD CONSTRAINT fk_user_chip_user FOREIGN KEY (id_user_app) REFERENCES security.user_app(id_user_app);
ALTER TABLE security.user_chip ADD CONSTRAINT fk_user_chip_chip FOREIGN KEY (id_chip) REFERENCES academic.chip(id_chip);
