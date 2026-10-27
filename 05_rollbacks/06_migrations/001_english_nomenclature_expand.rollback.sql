DROP TRIGGER sync_role_name ON roleandpermission.role;
DROP TRIGGER sync_permission_description ON roleandpermission.permission;
DROP TRIGGER sync_user_role_assigned_at ON roleandpermission.user_role;
DROP FUNCTION roleandpermission.sync_english_nomenclature();
ALTER TABLE roleandpermission.role DROP COLUMN role_name;
ALTER TABLE roleandpermission.permission DROP COLUMN description;
ALTER TABLE roleandpermission.user_role DROP COLUMN assigned_at;

ALTER TABLE notification.notification DROP CONSTRAINT notification_category_check;
UPDATE notification.notification SET category = CASE category
    WHEN 'SECURITY' THEN 'SEGURIDAD'
    WHEN 'ACADEMIC' THEN 'ACADEMICO'
    WHEN 'ATTENDANCE' THEN 'ASISTENCIA'
    WHEN 'FACIAL_RECOGNITION' THEN 'RECONOCIMIENTO_FACIAL'
    WHEN 'TRANSFER' THEN 'TRASLADO'
    ELSE category END;
ALTER TABLE notification.notification ADD CONSTRAINT notification_category_check CHECK (
    category IN ('SEGURIDAD', 'ACADEMICO', 'ASISTENCIA', 'RECONOCIMIENTO_FACIAL', 'TRASLADO')
);
