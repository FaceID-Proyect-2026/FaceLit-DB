-- Preserve the column and consent versions owned by main's historical DDL.
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM public.databasechangelog
        WHERE id = 'facelit-terms-acceptance-notice-version'
          AND author = 'facelit'
    ) THEN
        ALTER TABLE legal.terms_acceptance DROP COLUMN notice_version;
    END IF;
END;
$$;
