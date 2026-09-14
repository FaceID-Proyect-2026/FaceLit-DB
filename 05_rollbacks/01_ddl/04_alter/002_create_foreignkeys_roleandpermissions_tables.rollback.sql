ALTER TABLE roleandpermission.role_permission DROP CONSTRAINT IF EXISTS fk_role_permission_permission;
ALTER TABLE roleandpermission.role_permission DROP CONSTRAINT IF EXISTS fk_role_permission_role;
ALTER TABLE roleandpermission.user_role DROP CONSTRAINT IF EXISTS fk_user_role_role;
ALTER TABLE roleandpermission.user_role DROP CONSTRAINT IF EXISTS fk_user_role_user;
