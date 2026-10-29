-- Synthetic rows only, on the disposable migration-test database.
INSERT INTO roleandpermission.role(id_role, name_rol)
VALUES ('50000000-0000-0000-0000-000000000001', 'H50_ROLE');
INSERT INTO roleandpermission.permission(id_permission, name_permission, descripcion)
VALUES ('50000000-0000-0000-0000-000000000002', 'h50_fixture', 'Descripción original');
INSERT INTO security.user_app(id_user_app, first_name, last_name, account_status, number_document)
VALUES ('50000000-0000-0000-0000-000000000003', 'Migration', 'Fixture', 'ACTIVE', '98766001');
INSERT INTO roleandpermission.user_role(id_user_role, id_user_app, id_role, asigned_at)
VALUES ('50000000-0000-0000-0000-000000000004', '50000000-0000-0000-0000-000000000003',
        '50000000-0000-0000-0000-000000000001', '2020-01-02T03:04:05Z');
INSERT INTO notification.notification(id_user_app, category, message, channel)
SELECT '50000000-0000-0000-0000-000000000003', category, 'H50 fixture', 'APP'
FROM unnest(ARRAY['SEGURIDAD', 'ACADEMICO', 'ASISTENCIA', 'RECONOCIMIENTO_FACIAL', 'TRASLADO']) AS category;
