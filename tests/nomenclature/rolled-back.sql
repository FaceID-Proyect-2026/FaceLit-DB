DO $$
BEGIN
    ASSERT NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'roleandpermission'
                       AND table_name IN ('role','permission','user_role')
                       AND column_name IN ('role_name', 'description', 'assigned_at')), 'Canonical columns remain after rollback';
    ASSERT (SELECT name_rol = 'H50_ROLE' FROM roleandpermission.role WHERE id_role = '50000000-0000-0000-0000-000000000001'), 'Legacy role not restored';
    ASSERT (SELECT descripcion = 'Descripción original' FROM roleandpermission.permission WHERE name_permission = 'h50_fixture'), 'Legacy description not restored';
    ASSERT (SELECT asigned_at = '2020-01-02T03:04:05Z'::timestamptz FROM roleandpermission.user_role
            WHERE id_user_role = '50000000-0000-0000-0000-000000000004'), 'Legacy timestamp not restored';
    ASSERT (SELECT count(*) = 5 AND count(DISTINCT category) = 5 FROM notification.notification
            WHERE message = 'H50 fixture' AND category IN ('SEGURIDAD','ACADEMICO','ASISTENCIA','RECONOCIMIENTO_FACIAL','TRASLADO')), 'Legacy category values not restored';
    ASSERT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'facialrecognition.facial_event'::regclass
                   AND conname = 'fk_facial_event_apprendice'), 'Original FK name not restored';
END $$;
