ALTER TABLE security.user_configuration DROP CONSTRAINT user_configuration_language_check;
-- Retain PR temporarily for old application versions; new writes use ISO PT.
ALTER TABLE security.user_configuration ADD CONSTRAINT user_configuration_language_check
    CHECK (language IN ('ES', 'EN', 'PT', 'PR', 'FR', 'DE'));
UPDATE security.user_configuration SET language = 'PT' WHERE language = 'PR';
