-- 05_rollbacks/02_dml/00_inserts/002_seed_coordinator.rollback.sql
-- Deshace el seed del coordinador identificado por su numero de documento.

DELETE FROM roleandpermission.user_role
WHERE id_user_app = (
    SELECT id_user_app FROM security.user_app
    WHERE number_document = '${SEED_COORDINATOR_DOCUMENT}'
);

DELETE FROM security.credential
WHERE id_user_app = (
    SELECT id_user_app FROM security.user_app
    WHERE number_document = '${SEED_COORDINATOR_DOCUMENT}'
);

DELETE FROM security.user_app
WHERE number_document = '${SEED_COORDINATOR_DOCUMENT}';
