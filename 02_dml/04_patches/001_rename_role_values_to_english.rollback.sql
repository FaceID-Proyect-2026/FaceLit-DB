UPDATE roleandpermission.role
SET name_rol = CASE name_rol
    WHEN 'APPRENTICE' THEN 'APRENDIZ'
    WHEN 'COORDINATOR' THEN 'COORDINADOR'
    ELSE name_rol
END,
    updated_at = NOW(),
    updated_by = 'liquibase-role-migration-rollback'
WHERE name_rol IN ('APPRENTICE', 'COORDINATOR');