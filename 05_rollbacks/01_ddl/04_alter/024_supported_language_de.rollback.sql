-- Refuse a lossy rollback: resolve DE preferences explicitly before contracting the supported set.
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM security.user_configuration WHERE language = 'DE') THEN
        RAISE EXCEPTION 'Cannot remove DE while users still have that preference';
    END IF;
    ALTER TABLE security.user_configuration DROP CONSTRAINT user_configuration_language_check;
    ALTER TABLE security.user_configuration ADD CONSTRAINT user_configuration_language_check
        CHECK (language IN ('ES', 'EN', 'PR', 'FR'));
END $$;
