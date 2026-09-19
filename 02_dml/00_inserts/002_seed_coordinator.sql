-- 02_dml/00_inserts/002_seed_coordinator.sql
-- Semilla del primer Coordinador -- VERSION CON DATOS QUEMADOS.
-- Idempotente: si ya existe un user_app con ese numero de documento, no inserta de nuevo.
-- Requiere que el rol COORDINATOR ya exista en roleandpermission.role (lo crea seed.sql).

DO $$
DECLARE
    v_id_role     UUID;
    v_id_user_app UUID;

    -- === DATOS QUEMADOS: sin ${} en ningun lado, solo el valor entre comillas ===
    v_first_name     VARCHAR := 'Maria';
    v_last_name      VARCHAR := 'Rodriguez';
    v_document       VARCHAR := '1000000000';
    v_email          VARCHAR := 'maria.rodriguez@example.com';
    -- IMPORTANTE: este NO es un hash real, es un valor de relleno.
    -- '$Maria123!' que tenias antes NO es un hash BCrypt, es la contraseña en texto plano
    -- puesta a mano -- eso es justo lo que el flujo pide evitar. Genera uno real
    -- (ver LEEME del zip anterior: node -e "console.log(require('bcryptjs').hashSync('...',10))")
    v_password_hash  VARCHAR := '$2a$10$Oe.5OZVxvcu2Mt1RuGMU6ukZ7BcVQ7vRUtsvISbY6UYvzEsBGv1g.';
    -- ================================================================

BEGIN
    SELECT id_role INTO v_id_role
    FROM roleandpermission.role
    WHERE name_rol = 'COORDINATOR';

    IF v_id_role IS NULL THEN
        RAISE EXCEPTION 'No existe el rol COORDINATOR en roleandpermission.role. Ejecuta primero el changeset facelit-model-seed.';
    END IF;

    SELECT id_user_app INTO v_id_user_app
    FROM security.user_app
    WHERE number_document = v_document;

    IF v_id_user_app IS NULL THEN

        INSERT INTO security.user_app (
            id_user_app, first_name, last_name, account_status, number_document,
            created_at, created_by
        ) VALUES (
            uuid_generate_v4(), v_first_name, v_last_name, 'ACTIVE', v_document,
            NOW(), 'liquibase-seed'
        )
        RETURNING id_user_app INTO v_id_user_app;

        INSERT INTO security.credential (
            id_credential, id_user_app, email, password_hash, credential_status,
            created_at, created_by
        ) VALUES (
            uuid_generate_v4(), v_id_user_app, v_email, v_password_hash, 'ACTIVE',
            NOW(), 'liquibase-seed'
        );

        INSERT INTO roleandpermission.user_role (
            id_user_role, id_user_app, id_role, asigned_at, created_at, created_by
        ) VALUES (
            uuid_generate_v4(), v_id_user_app, v_id_role, NOW(), NOW(), 'liquibase-seed'
        );

    ELSE
        RAISE NOTICE 'Ya existe un user_app con number_document=%, no se inserta de nuevo.', v_document;
    END IF;
END $$;
