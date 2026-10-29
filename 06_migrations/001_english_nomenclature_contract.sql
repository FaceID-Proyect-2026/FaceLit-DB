-- Apply once every application uses the canonical names. For a coordinated local
-- upgrade stop the backend, apply both stages, then start the updated backend.
DROP TRIGGER sync_role_name ON roleandpermission.role;
DROP TRIGGER sync_permission_description ON roleandpermission.permission;
DROP TRIGGER sync_user_role_assigned_at ON roleandpermission.user_role;
DROP FUNCTION roleandpermission.sync_english_nomenclature();

ALTER TABLE roleandpermission.role DROP COLUMN name_rol;
ALTER TABLE roleandpermission.permission DROP COLUMN descripcion;
ALTER TABLE roleandpermission.user_role DROP COLUMN asigned_at;
ALTER TABLE roleandpermission.user_role ALTER COLUMN assigned_at SET DEFAULT NOW();
ALTER TABLE facialrecognition.facial_event RENAME CONSTRAINT
    fk_facial_event_apprendice TO fk_facial_event_apprentice;

UPDATE notification.notification SET category = CASE category
    WHEN 'SEGURIDAD' THEN 'SECURITY'
    WHEN 'ACADEMICO' THEN 'ACADEMIC'
    WHEN 'ASISTENCIA' THEN 'ATTENDANCE'
    WHEN 'RECONOCIMIENTO_FACIAL' THEN 'FACIAL_RECOGNITION'
    WHEN 'TRASLADO' THEN 'TRANSFER'
    ELSE category END;
ALTER TABLE notification.notification DROP CONSTRAINT notification_category_check;
ALTER TABLE notification.notification ADD CONSTRAINT notification_category_check CHECK (
    category IN ('SECURITY', 'ACADEMIC', 'ATTENDANCE', 'FACIAL_RECOGNITION', 'TRANSFER')
);
