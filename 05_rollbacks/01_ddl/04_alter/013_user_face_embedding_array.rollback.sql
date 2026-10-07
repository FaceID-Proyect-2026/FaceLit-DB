ALTER TABLE facialrecognition.user_face
  ALTER COLUMN embedding TYPE FLOAT8[]
  USING embedding::REAL[]::FLOAT8[];
