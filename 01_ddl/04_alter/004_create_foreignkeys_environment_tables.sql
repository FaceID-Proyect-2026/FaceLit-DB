ALTER TABLE environment.chip_environment ADD CONSTRAINT fk_chip_environment_chip FOREIGN KEY (id_chip) REFERENCES academic.chip(id_chip);
ALTER TABLE environment.chip_environment ADD CONSTRAINT fk_chip_environment_environment FOREIGN KEY (id_environment) REFERENCES environment.environment(id_environment);
ALTER TABLE environment.record_environment ADD CONSTRAINT fk_record_environment_environment FOREIGN KEY (id_environment) REFERENCES environment.environment(id_environment);
ALTER TABLE environment.record_environment ADD CONSTRAINT fk_record_environment_chip FOREIGN KEY (id_chip) REFERENCES academic.chip(id_chip);
ALTER TABLE environment.record_environment ADD CONSTRAINT fk_record_environment_instructor FOREIGN KEY (id_instructor_in_charge) REFERENCES academic.instructor(id_instructor);
