-- Conserva el registro facial activo mas antiguo de cada identidad y desactiva
-- los posteriores que superen el umbral de duplicado de la aplicacion.
-- La comparacion se serializa por el orden de alta para que el resultado sea
-- determinista y quede trazabilidad mediante deleted_at/deleted_by.
DO $$
DECLARE
    candidate RECORD;
BEGIN
    FOR candidate IN
        SELECT id_user_face, created_at, embedding, embedding_dimension
        FROM facialrecognition.user_face
        WHERE status = 'ACTIVE'
          AND deleted_at IS NULL
        ORDER BY created_at, id_user_face
    LOOP
        IF EXISTS (
            SELECT 1
            FROM facialrecognition.user_face kept
            WHERE kept.status = 'ACTIVE'
              AND kept.deleted_at IS NULL
              AND (kept.created_at, kept.id_user_face)
                    < (candidate.created_at, candidate.id_user_face)
              AND COALESCE(kept.embedding_dimension, vector_dims(kept.embedding))
                    = COALESCE(candidate.embedding_dimension, vector_dims(candidate.embedding))
              AND 1 - (kept.embedding <=> candidate.embedding) >= 0.65
        ) THEN
            UPDATE facialrecognition.user_face
            SET status = 'DELETED',
                deleted_at = clock_timestamp(),
                deleted_by = 'liquibase:duplicate-face-repair',
                updated_at = clock_timestamp(),
                updated_by = 'liquibase:duplicate-face-repair'
            WHERE id_user_face = candidate.id_user_face;
        END IF;
    END LOOP;
END $$;
