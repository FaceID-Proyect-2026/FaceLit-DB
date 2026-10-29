-- Keep both names writable while consumers move to the English columns.
ALTER TABLE roleandpermission.role ADD COLUMN role_name VARCHAR(50);
UPDATE roleandpermission.role SET role_name = name_rol;
ALTER TABLE roleandpermission.role ALTER COLUMN role_name SET NOT NULL;
ALTER TABLE roleandpermission.role ADD CONSTRAINT role_role_name_key UNIQUE (role_name);

ALTER TABLE roleandpermission.permission ADD COLUMN description TEXT;
UPDATE roleandpermission.permission SET description = descripcion;

ALTER TABLE roleandpermission.user_role ADD COLUMN assigned_at TIMESTAMPTZ;
UPDATE roleandpermission.user_role SET assigned_at = asigned_at;
ALTER TABLE roleandpermission.user_role ALTER COLUMN assigned_at SET NOT NULL;

ALTER TABLE notification.notification DROP CONSTRAINT notification_category_check;
ALTER TABLE notification.notification ADD CONSTRAINT notification_category_check CHECK (
    category IN ('SECURITY', 'ACADEMIC', 'ATTENDANCE', 'FACIAL_RECOGNITION', 'TRANSFER',
                 'SEGURIDAD', 'ACADEMICO', 'ASISTENCIA', 'RECONOCIMIENTO_FACIAL', 'TRASLADO')
);
