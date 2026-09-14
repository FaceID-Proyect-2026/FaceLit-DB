-- V4: roles
INSERT INTO roleandpermission.role (id_role, name_rol, created_at)
VALUES
    (uuid_generate_v4(), 'APRENDIZ', NOW()),
    (uuid_generate_v4(), 'INSTRUCTOR', NOW()),
    (uuid_generate_v4(), 'COORDINADOR', NOW())
ON CONFLICT (name_rol) DO NOTHING;

-- V4: permisos, uno por cada accion real que quedo definida por modulo/rol en el diseño
INSERT INTO roleandpermission.permission (id_permission, name_permission, descripcion, created_at)
VALUES
    -- Perfil y Personalizacion (RF-9) - los 3 roles
    (uuid_generate_v4(), 'VIEW_OWN_PROFILE', 'Ver perfil propio (solo lectura)', NOW()),
    (uuid_generate_v4(), 'MANAGE_OWN_CONFIGURATION', 'Configurar idioma, tema y notificaciones propias', NOW()),

    -- Notificaciones (RF-8) - los 3 roles, cada uno ve solo las suyas
    (uuid_generate_v4(), 'VIEW_OWN_NOTIFICATIONS', 'Ver y marcar como leidas las notificaciones propias', NOW()),

    -- Reconocimiento Facial (RF-5.4) - Aprendiz
    (uuid_generate_v4(), 'VIEW_OWN_ATTENDANCE', 'Ver la asistencia propia', NOW()),
    (uuid_generate_v4(), 'REGISTER_FACE', 'Registrar el rostro propio (una sola vez)', NOW()),
    (uuid_generate_v4(), 'REQUEST_FACE_RESET', 'Solicitar restablecimiento del registro facial propio', NOW()),

    -- Gestion de Ambiente / Sesion de Reconocimiento Facial - Instructor
    (uuid_generate_v4(), 'CONFIGURE_RECOGNITION_SESSION', 'Configurar y editar sesiones de reconocimiento facial (ambiente, ficha, instructor a cargo, ajustes)', NOW()),
    (uuid_generate_v4(), 'VIEW_FICHA_ATTENDANCE', 'Ver la asistencia de las fichas asignadas', NOW()),

    -- Gestion Academica (RF-3) y Gestion de Usuarios - Coordinador
    (uuid_generate_v4(), 'VIEW_ALL_ATTENDANCE', 'Ver la asistencia de cualquier programa, ficha o aprendiz', NOW()),
    (uuid_generate_v4(), 'MANAGE_ACADEMIC', 'Crear, editar, desactivar y trasladar programas, fichas, aprendices e instructores (CSV y manual)', NOW()),
    (uuid_generate_v4(), 'MANAGE_USERS', 'Crear y editar usuarios con cualquier rol (Aprendiz, Instructor o Coordinador)', NOW()),
    (uuid_generate_v4(), 'RESOLVE_FACE_RESET_REQUEST', 'Aceptar o rechazar solicitudes de restablecimiento de reconocimiento facial', NOW())
ON CONFLICT (name_permission) DO NOTHING;

-- APRENDIZ
INSERT INTO roleandpermission.role_permission (id_role_permission, id_role, id_permission, assigned_at, created_at)
SELECT uuid_generate_v4(), r.id_role, p.id_permission, NOW(), NOW()
FROM roleandpermission.role r
CROSS JOIN roleandpermission.permission p
WHERE r.name_rol = 'APRENDIZ'
  AND p.name_permission IN (
      'VIEW_OWN_PROFILE',
      'MANAGE_OWN_CONFIGURATION',
      'VIEW_OWN_NOTIFICATIONS',
      'VIEW_OWN_ATTENDANCE',
      'REGISTER_FACE',
      'REQUEST_FACE_RESET'
  )
ON CONFLICT (id_role, id_permission) DO NOTHING;

-- INSTRUCTOR
INSERT INTO roleandpermission.role_permission (id_role_permission, id_role, id_permission, assigned_at, created_at)
SELECT uuid_generate_v4(), r.id_role, p.id_permission, NOW(), NOW()
FROM roleandpermission.role r
CROSS JOIN roleandpermission.permission p
WHERE r.name_rol = 'INSTRUCTOR'
  AND p.name_permission IN (
      'VIEW_OWN_PROFILE',
      'MANAGE_OWN_CONFIGURATION',
      'VIEW_OWN_NOTIFICATIONS',
      'CONFIGURE_RECOGNITION_SESSION',
      'VIEW_FICHA_ATTENDANCE'
  )
ON CONFLICT (id_role, id_permission) DO NOTHING;

-- COORDINADOR
INSERT INTO roleandpermission.role_permission (id_role_permission, id_role, id_permission, assigned_at, created_at)
SELECT uuid_generate_v4(), r.id_role, p.id_permission, NOW(), NOW()
FROM roleandpermission.role r
CROSS JOIN roleandpermission.permission p
WHERE r.name_rol = 'COORDINADOR'
  AND p.name_permission IN (
      'VIEW_OWN_PROFILE',
      'MANAGE_OWN_CONFIGURATION',
      'VIEW_OWN_NOTIFICATIONS',
      'VIEW_ALL_ATTENDANCE',
      'MANAGE_ACADEMIC',
      'MANAGE_USERS',
      'RESOLVE_FACE_RESET_REQUEST'
  )
ON CONFLICT (id_role, id_permission) DO NOTHING;