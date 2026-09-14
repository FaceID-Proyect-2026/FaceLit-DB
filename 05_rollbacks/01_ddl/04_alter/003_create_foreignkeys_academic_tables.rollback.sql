ALTER TABLE academic.chip DROP CONSTRAINT IF EXISTS fk_chip_program;
ALTER TABLE academic.instructor_program DROP CONSTRAINT IF EXISTS fk_instructor_program_program;
ALTER TABLE academic.instructor_program DROP CONSTRAINT IF EXISTS fk_instructor_program_instructor;
ALTER TABLE academic.instructor DROP CONSTRAINT IF EXISTS fk_instructor_user;
