-- Historical decisions do not establish acceptance of the current privacy notice.
ALTER TABLE legal.terms_acceptance ADD COLUMN notice_version VARCHAR(64);
UPDATE legal.terms_acceptance SET notice_version = 'legacy-unversioned';
ALTER TABLE legal.terms_acceptance ALTER COLUMN notice_version SET NOT NULL;
