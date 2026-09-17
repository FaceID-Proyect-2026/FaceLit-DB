DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM roleandpermission.role
        WHERE name_rol IN ('APRENDIZ', 'COORDINADOR')
    ) AND EXISTS (
        SELECT 1
        FROM roleandpermission.role
        WHERE name_rol IN ('APPRENTICE', 'COORDINATOR')
    ) THEN
        RAISE EXCEPTION 'Cannot rename roles because Spanish and English values already coexist.';
    END IF;

    UPDATE roleandpermission.role
    SET name_rol = CASE name_rol
        WHEN 'APRENDIZ' THEN 'APPRENTICE'
        WHEN 'COORDINADOR' THEN 'COORDINATOR'
        ELSE name_rol
    END,
        updated_at = NOW(),
        updated_by = 'liquibase-role-migration'
    WHERE name_rol IN ('APRENDIZ', 'COORDINADOR');
END $$;