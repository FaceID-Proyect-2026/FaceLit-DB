-- Expand the existing language contract without rewriting applied migrations or existing preferences.
DO $$
DECLARE constraint_name text;
BEGIN
    FOR constraint_name IN
        SELECT c.conname FROM pg_constraint c
        JOIN pg_attribute a ON a.attrelid = c.conrelid AND a.attnum = ANY(c.conkey)
        WHERE c.conrelid = 'security.user_configuration'::regclass
          AND c.contype = 'c' AND a.attname = 'language'
    LOOP
        EXECUTE format('ALTER TABLE security.user_configuration DROP CONSTRAINT %I', constraint_name);
    END LOOP;
    ALTER TABLE security.user_configuration ADD CONSTRAINT user_configuration_language_check
        CHECK (language IN ('ES', 'EN', 'PR', 'FR', 'DE'));
END $$;
