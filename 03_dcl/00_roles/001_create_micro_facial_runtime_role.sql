DO $role$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'facelit_micro_facial') THEN
        CREATE ROLE facelit_micro_facial NOLOGIN;
    END IF;
END
$role$;
