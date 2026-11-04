-- Keep previous consent decisions intact and ensure the current notice gets a new decision per user.
ALTER TABLE legal.terms_acceptance
    ADD COLUMN notice_version VARCHAR(64);

UPDATE legal.terms_acceptance
SET notice_version = 'legacy:' || id_acceptance::TEXT
WHERE notice_version IS NULL;

ALTER TABLE legal.terms_acceptance
    ALTER COLUMN notice_version SET NOT NULL;

CREATE UNIQUE INDEX uq_terms_acceptance_user_notice_version
    ON legal.terms_acceptance (id_user_app, notice_version);
