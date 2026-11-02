-- Database boundary owned by FaceLit-DB and consumed by the coordinated HU-48 apps.
DO $contract$
DECLARE entry record;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'facelit_micro_facial' AND NOT rolcanlogin
                   AND NOT rolsuper AND NOT rolcreaterole AND NOT rolcreatedb) THEN
        RAISE EXCEPTION 'micro-facial group role must be a non-privileged NOLOGIN role';
    END IF;
    IF NOT has_table_privilege('facelit_micro_facial', 'facialrecognition.user_face', 'SELECT')
       OR NOT has_table_privilege('facelit_micro_facial', 'facialrecognition.user_face', 'INSERT')
       OR NOT has_table_privilege('facelit_micro_facial', 'facialrecognition.user_face', 'UPDATE')
       OR has_table_privilege('facelit_micro_facial', 'facialrecognition.user_face', 'DELETE') THEN
        RAISE EXCEPTION 'template privileges violate the facial runtime contract';
    END IF;
    IF NOT has_column_privilege('facelit_micro_facial', 'facialrecognition.face_reset_request', 'authorization_token', 'SELECT')
       OR NOT has_column_privilege('facelit_micro_facial', 'facialrecognition.face_reset_request', 'consumed_at', 'UPDATE')
       OR has_column_privilege('facelit_micro_facial', 'facialrecognition.face_reset_request', 'request_status', 'UPDATE')
       OR has_table_privilege('facelit_micro_facial', 'facialrecognition.face_reset_request', 'INSERT')
       OR has_table_privilege('facelit_micro_facial', 'facialrecognition.face_reset_request', 'DELETE') THEN
        RAISE EXCEPTION 'reset authorization privileges violate the runtime contract';
    END IF;
    FOR entry IN
        SELECT schemaname, tablename FROM pg_tables
        WHERE schemaname IN ('security', 'academic', 'environment', 'notification', 'legal', 'roleandpermission')
           OR (schemaname = 'facialrecognition' AND tablename NOT IN ('user_face', 'face_reset_request'))
    LOOP
        IF has_any_column_privilege('facelit_micro_facial',
                format('%I.%I', entry.schemaname, entry.tablename), 'SELECT,INSERT,UPDATE,REFERENCES')
           OR has_table_privilege('facelit_micro_facial',
                format('%I.%I', entry.schemaname, entry.tablename), 'DELETE,TRUNCATE,TRIGGER') THEN
            RAISE EXCEPTION 'micro-facial unexpectedly accesses %.%', entry.schemaname, entry.tablename;
        END IF;
    END LOOP;
END
$contract$;
