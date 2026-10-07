WITH duplicated_events AS (
    SELECT
        id_facial_event,
        ROW_NUMBER() OVER (
            PARTITION BY id_record_environment, id_apprentice, event_type
            ORDER BY event_datetime ASC, created_at ASC, id_facial_event ASC
        ) AS duplicate_rank
    FROM facialrecognition.facial_event
    WHERE deleted_at IS NULL
)
UPDATE facialrecognition.facial_event fe
SET deleted_at = NOW(),
    deleted_by = 'liquibase-unique-facial-event-attendance'
FROM duplicated_events de
WHERE fe.id_facial_event = de.id_facial_event
  AND de.duplicate_rank > 1;

CREATE UNIQUE INDEX uq_facial_event_attendance_once
ON facialrecognition.facial_event (id_record_environment, id_apprentice, event_type)
WHERE deleted_at IS NULL;
