UPDATE academic.program
SET updated_at = created_at
WHERE updated_at IS NULL;

ALTER TABLE academic.program
    ALTER COLUMN updated_at SET DEFAULT NOW();
