ALTER TABLE academic.instructor ADD CONSTRAINT fk_instructor_user FOREIGN KEY (id_user_app) REFERENCES security.user_app(id_user_app);
ALTER TABLE academic.instructor_program ADD CONSTRAINT fk_instructor_program_instructor FOREIGN KEY (id_instructor) REFERENCES academic.instructor(id_instructor);
ALTER TABLE academic.instructor_program ADD CONSTRAINT fk_instructor_program_program FOREIGN KEY (id_program) REFERENCES academic.program(id_program);
ALTER TABLE academic.chip ADD CONSTRAINT fk_chip_program FOREIGN KEY (id_program) REFERENCES academic.program(id_program);
