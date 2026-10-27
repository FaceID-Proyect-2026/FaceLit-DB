-- Restore the expansion state, including legacy writers, without losing rows.
ALTER TABLE roleandpermission.role ADD COLUMN name_rol VARCHAR(50);
UPDATE roleandpermission.role SET name_rol = role_name;
ALTER TABLE roleandpermission.role ALTER COLUMN name_rol SET NOT NULL;
ALTER TABLE roleandpermission.role ADD CONSTRAINT role_name_rol_key UNIQUE (name_rol);

ALTER TABLE roleandpermission.permission ADD COLUMN descripcion TEXT;
UPDATE roleandpermission.permission SET descripcion = description;

ALTER TABLE roleandpermission.user_role ADD COLUMN asigned_at TIMESTAMPTZ;
UPDATE roleandpermission.user_role SET asigned_at = assigned_at;
ALTER TABLE roleandpermission.user_role ALTER COLUMN asigned_at SET NOT NULL;
ALTER TABLE roleandpermission.user_role ALTER COLUMN asigned_at SET DEFAULT NOW();
ALTER TABLE roleandpermission.user_role ALTER COLUMN assigned_at DROP DEFAULT;
ALTER TABLE facialrecognition.facial_event RENAME CONSTRAINT
    fk_facial_event_apprentice TO fk_facial_event_apprendice;

ALTER TABLE notification.notification DROP CONSTRAINT notification_category_check;
ALTER TABLE notification.notification ADD CONSTRAINT notification_category_check CHECK (
    category IN ('SECURITY', 'ACADEMIC', 'ATTENDANCE', 'FACIAL_RECOGNITION', 'TRANSFER',
                 'SEGURIDAD', 'ACADEMICO', 'ASISTENCIA', 'RECONOCIMIENTO_FACIAL', 'TRASLADO')
);
