CREATE TABLE security.user_app(
    id_user_app UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    first_name VARCHAR(60) NOT NULL,
    last_name VARCHAR(60) NOT NULL,
    account_status VARCHAR(20) NOT NULL,
    number_document VARCHAR(10) NOT NULL UNIQUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by VARCHAR(100),
    updated_at TIMESTAMPTZ,
    updated_by VARCHAR(100),
    deleted_by VARCHAR(100),
    deleted_at TIMESTAMPTZ
);

CREATE TABLE security.credential(
    id_credential UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    id_user_app UUID NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    credential_status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    failed_attempts INTEGER NOT NULL DEFAULT 0,
    locked_until TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by VARCHAR(100),
    updated_at TIMESTAMPTZ,
    updated_by VARCHAR(100),
    deleted_by VARCHAR(100),
    deleted_at TIMESTAMPTZ,
    CONSTRAINT chk_failed_attempts_non_negative CHECK (failed_attempts >= 0)
);

CREATE TABLE security.password_recovery (
    id_password_recovery UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    id_user_app UUID NOT NULL,
    token VARCHAR(255) NOT NULL,
    expiration_date TIMESTAMPTZ NOT NULL,
    used BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by VARCHAR(100),
    updated_at TIMESTAMPTZ,
    updated_by VARCHAR(100),
    deleted_by VARCHAR(100),
    deleted_at TIMESTAMPTZ
);

CREATE TABLE security.user_session (
    id_user_session UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    id_user_app UUID NOT NULL,
    start_date TIMESTAMPTZ NOT NULL,
    end_date TIMESTAMPTZ,
    session_status VARCHAR(20) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by VARCHAR(100),
    updated_at TIMESTAMPTZ,
    updated_by VARCHAR(100),
    deleted_by VARCHAR(100),
    deleted_at TIMESTAMPTZ
);

CREATE TABLE security.user_configuration (
    id_user_configuration UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    id_user_app UUID NOT NULL UNIQUE,
    notifications_active BOOLEAN NOT NULL DEFAULT TRUE,
    dark_mode BOOLEAN NOT NULL DEFAULT FALSE,
    language VARCHAR(2) NOT NULL CHECK (language IN ('ES', 'EN', 'PR', 'FR')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by VARCHAR(100),
    updated_at TIMESTAMPTZ,
    updated_by VARCHAR(100),
    deleted_by VARCHAR(100),
    deleted_at TIMESTAMPTZ
);

CREATE TABLE security.user_chip(
    id_user_chip UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    id_user_app UUID NOT NULL,
    id_chip UUID NOT NULL,
    assignment_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    state VARCHAR(20) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by VARCHAR(100),
    updated_at TIMESTAMPTZ,
    updated_by VARCHAR(100),
    deleted_by VARCHAR(100),
    deleted_at TIMESTAMPTZ
);