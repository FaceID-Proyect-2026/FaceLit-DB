BEGIN;
DO $$
DECLARE role_id UUID; owner_id UUID := '50000000-0000-0000-0000-000000000003';
BEGIN
    ASSERT (SELECT bool_and(name_rol = role_name) FROM roleandpermission.role), 'Role backfill differs';
    ASSERT (SELECT bool_and(asigned_at = assigned_at) FROM roleandpermission.user_role), 'Timestamp backfill differs';
    ASSERT NOT EXISTS (SELECT 1 FROM roleandpermission.permission WHERE descripcion IS DISTINCT FROM description), 'Description backfill differs';
    INSERT INTO roleandpermission.role(name_rol) VALUES ('H50_LEGACY') RETURNING id_role INTO role_id;
    ASSERT (SELECT role_name = 'H50_LEGACY' FROM roleandpermission.role WHERE id_role = role_id), 'Legacy insert not synchronized';
    UPDATE roleandpermission.role SET role_name = 'H50_CANONICAL' WHERE id_role = role_id;
    ASSERT (SELECT name_rol = 'H50_CANONICAL' FROM roleandpermission.role WHERE id_role = role_id), 'Canonical update not synchronized';
    UPDATE roleandpermission.role SET name_rol = 'H50_UPDATED' WHERE id_role = role_id;
    ASSERT (SELECT role_name = 'H50_UPDATED' FROM roleandpermission.role WHERE id_role = role_id), 'Legacy update not synchronized';
    BEGIN
        UPDATE roleandpermission.role SET name_rol = 'H50_A', role_name = 'H50_B' WHERE id_role = role_id;
        ASSERT FALSE, 'Conflicting writes were accepted';
    EXCEPTION WHEN raise_exception THEN NULL;
    END;
    INSERT INTO roleandpermission.role(role_name) VALUES ('H50_NEW');
    INSERT INTO roleandpermission.user_role(id_user_app, id_role, assigned_at)
    VALUES (owner_id, role_id, '2021-03-04T05:06:07Z');
    ASSERT (SELECT asigned_at = '2021-03-04T05:06:07Z'::timestamptz FROM roleandpermission.user_role
            WHERE id_user_app = owner_id AND id_role = role_id), 'Canonical timestamp insert lost';
    UPDATE roleandpermission.permission SET description = NULL WHERE name_permission = 'h50_fixture';
    ASSERT (SELECT descripcion IS NULL FROM roleandpermission.permission WHERE name_permission = 'h50_fixture'), 'Null description not synchronized';
END $$;
ROLLBACK;
