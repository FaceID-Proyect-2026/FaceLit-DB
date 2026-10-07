ALTER TABLE facialrecognition.user_face
  ALTER COLUMN embedding TYPE vector
  USING CASE
    WHEN embedding IS NULL THEN NULL
    WHEN pg_typeof(embedding)::text = 'vector' THEN embedding::vector
    ELSE embedding::vector
  END;
