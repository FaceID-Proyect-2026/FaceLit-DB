DROP INDEX IF EXISTS legal.uq_terms_acceptance_user_notice_version;

ALTER TABLE legal.terms_acceptance
    DROP COLUMN IF EXISTS notice_version;
