DO $membership$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'facelit_micro_runtime') THEN
        REVOKE facelit_micro_facial FROM facelit_micro_runtime;
    END IF;
END
$membership$;

DROP ROLE IF EXISTS facelit_micro_facial;
