ALTER TABLE environment.record_environment DROP CONSTRAINT IF EXISTS fk_record_environment_instructor;
ALTER TABLE environment.record_environment DROP CONSTRAINT IF EXISTS fk_record_environment_chip;
ALTER TABLE environment.record_environment DROP CONSTRAINT IF EXISTS fk_record_environment_environment;
ALTER TABLE environment.chip_environment DROP CONSTRAINT IF EXISTS fk_chip_environment_environment;
ALTER TABLE environment.chip_environment DROP CONSTRAINT IF EXISTS fk_chip_environment_chip;
