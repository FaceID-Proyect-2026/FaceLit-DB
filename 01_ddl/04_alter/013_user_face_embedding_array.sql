ALTER TABLE facialrecognition.user_face
  ALTER COLUMN embedding TYPE FLOAT8[]
  USING CASE
    WHEN embedding IS NULL THEN NULL
    ELSE ARRAY[embedding]
  END;
