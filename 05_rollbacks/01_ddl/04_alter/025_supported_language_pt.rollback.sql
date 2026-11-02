UPDATE security.user_configuration SET language = 'PR' WHERE language = 'PT';
ALTER TABLE security.user_configuration DROP CONSTRAINT user_configuration_language_check;
ALTER TABLE security.user_configuration ADD CONSTRAINT user_configuration_language_check
    CHECK (language IN ('ES', 'EN', 'PR', 'FR', 'DE'));
