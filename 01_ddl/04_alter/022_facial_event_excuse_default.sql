-- Additive repair for databases created from the current changelog.
-- Historical changesets remain untouched so Liquibase checksums stay valid.
ALTER TABLE facialrecognition.facial_event
    ALTER COLUMN excuse SET DEFAULT FALSE;

UPDATE facialrecognition.facial_event
SET excuse = FALSE
WHERE attendance_status = 'ABSENT'
  AND excuse IS NULL;
