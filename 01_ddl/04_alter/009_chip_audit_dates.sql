UPDATE academic.chip
SET updated_at = created_at
WHERE updated_at IS NULL;

ALTER TABLE academic.chip
    ALTER COLUMN updated_at SET DEFAULT NOW();
