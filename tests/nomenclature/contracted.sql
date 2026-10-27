BEGIN;
DO $$
BEGIN
    ASSERT NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'roleandpermission'
                       AND column_name IN ('name_rol', 'descripcion', 'asigned_at')), 'Legacy columns remain';
    ASSERT (SELECT role_name = 'H50_ROLE' FROM roleandpermission.role WHERE id_role = '50000000-0000-0000-0000-000000000001'), 'Role value lost';
    ASSERT (SELECT description = 'Descripción original' FROM roleandpermission.permission WHERE name_permission = 'h50_fixture'), 'Description lost';
    ASSERT (SELECT assigned_at = '2020-01-02T03:04:05Z'::timestamptz FROM roleandpermission.user_role
            WHERE id_user_role = '50000000-0000-0000-0000-000000000004'), 'Assignment timestamp changed';
    ASSERT (SELECT count(*) = 5 AND count(DISTINCT category) = 5 FROM notification.notification
            WHERE message = 'H50 fixture' AND category IN ('SECURITY','ACADEMIC','ATTENDANCE','FACIAL_RECOGNITION','TRANSFER')), 'Category migration lost rows';
    ASSERT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'facialrecognition.facial_event'::regclass
                   AND conname = 'fk_facial_event_apprentice' AND contype = 'f'), 'Renamed FK missing';
    BEGIN
        INSERT INTO roleandpermission.role(role_name) VALUES ('H50_ROLE');
        ASSERT FALSE, 'Unique role name constraint missing';
    EXCEPTION WHEN unique_violation THEN NULL;
    END;
    BEGIN
        INSERT INTO notification.notification(id_user_app, category, message, channel)
        VALUES ('50000000-0000-0000-0000-000000000003', 'SEGURIDAD', 'Must fail', 'APP');
        ASSERT FALSE, 'Legacy categories remain writable after contraction';
    EXCEPTION WHEN check_violation THEN NULL;
    END;
END $$;
ROLLBACK;
