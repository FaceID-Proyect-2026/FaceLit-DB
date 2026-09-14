INSERT INTO roleandpermission.role (id_role, name_rol, created_at)
VALUES
    (uuid_generate_v4(), 'APRENDIZ', NOW()),
    (uuid_generate_v4(), 'INSTRUCTOR', NOW()),
    (uuid_generate_v4(), 'COORDINADOR', NOW())
ON CONFLICT (name_rol) DO NOTHING;

INSERT INTO roleandpermission.permission (id_permission, name_permission, descripcion, created_at)
VALUES
    (uuid_generate_v4(), 'VIEW_OWN_PROFILE', 'Ver perfil propio', NOW()),
    (uuid_generate_v4(), 'EDIT_OWN_PROFILE', 'Editar perfil propio', NOW()),
    (uuid_generate_v4(), 'VIEW_OWN_ATTENDANCE', 'Ver asistencia propia', NOW()),
    (uuid_generate_v4(), 'VIEW_FICHA_ATTENDANCE', 'Ver asistencia de ficha', NOW()),
    (uuid_generate_v4(), 'MANAGE_USERS', 'Gestionar usuarios', NOW()),
    (uuid_generate_v4(), 'MANAGE_ENVIRONMENTS', 'Gestionar ambientes', NOW()),
    (uuid_generate_v4(), 'MANAGE_FICHAS', 'Gestionar fichas', NOW()),
    (uuid_generate_v4(), 'MANAGE_TRAINING_PROGRAMS', 'Gestionar programas de formacion', NOW())
ON CONFLICT (name_permission) DO NOTHING;

INSERT INTO roleandpermission.role_permission (id_role_permission, id_role, id_permission, assigned_at, created_at)
SELECT uuid_generate_v4(), r.id_role, p.id_permission, NOW(), NOW()
FROM roleandpermission.role r
CROSS JOIN roleandpermission.permission p
WHERE r.name_rol = 'COORDINADOR'
  AND p.name_permission IN ('VIEW_OWN_PROFILE', 'EDIT_OWN_PROFILE', 'VIEW_FICHA_ATTENDANCE', 'MANAGE_USERS', 'MANAGE_ENVIRONMENTS', 'MANAGE_FICHAS', 'MANAGE_TRAINING_PROGRAMS')
ON CONFLICT (id_role, id_permission) DO NOTHING;

INSERT INTO roleandpermission.role_permission (id_role_permission, id_role, id_permission, assigned_at, created_at)
SELECT uuid_generate_v4(), r.id_role, p.id_permission, NOW(), NOW()
FROM roleandpermission.role r
CROSS JOIN roleandpermission.permission p
WHERE r.name_rol = 'INSTRUCTOR'
  AND p.name_permission IN ('VIEW_OWN_PROFILE', 'EDIT_OWN_PROFILE', 'VIEW_OWN_ATTENDANCE', 'VIEW_FICHA_ATTENDANCE')
ON CONFLICT (id_role, id_permission) DO NOTHING;

INSERT INTO roleandpermission.role_permission (id_role_permission, id_role, id_permission, assigned_at, created_at)
SELECT uuid_generate_v4(), r.id_role, p.id_permission, NOW(), NOW()
FROM roleandpermission.role r
CROSS JOIN roleandpermission.permission p
WHERE r.name_rol = 'APRENDIZ'
  AND p.name_permission IN ('VIEW_OWN_PROFILE', 'EDIT_OWN_PROFILE', 'VIEW_OWN_ATTENDANCE')
ON CONFLICT (id_role, id_permission) DO NOTHING;
