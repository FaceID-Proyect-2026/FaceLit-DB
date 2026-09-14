CREATE TABLE roleandpermission.role (
    id_role UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name_rol VARCHAR(50) NOT NULL UNIQUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by VARCHAR(100),
    updated_at TIMESTAMPTZ,
    updated_by VARCHAR(100),
    deleted_by VARCHAR(100),
    deleted_at TIMESTAMPTZ
);

CREATE TABLE roleandpermission.permission (
    id_permission UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name_permission VARCHAR(100) NOT NULL,
    descripcion TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by VARCHAR(100),
    updated_at TIMESTAMPTZ,
    updated_by VARCHAR(100),
    deleted_by VARCHAR(100),
    deleted_at TIMESTAMPTZ
);

CREATE TABLE roleandpermission.user_role (
    id_user_role UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    id_user_app UUID NOT NULL,
    id_role UUID NOT NULL,
    asigned_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by VARCHAR(100),
    updated_at TIMESTAMPTZ,
    updated_by VARCHAR(100),
    deleted_by VARCHAR(100),
    deleted_at TIMESTAMPTZ,
    CONSTRAINT uq_user_role UNIQUE (id_user_app, id_role)
);

CREATE TABLE roleandpermission.role_permission (
    id_role_permission UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    id_role UUID NOT NULL,
    id_permission UUID NOT NULL,
    assigned_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by VARCHAR(100),
    updated_at TIMESTAMPTZ,
    updated_by VARCHAR(100),
    deleted_by VARCHAR(100),
    deleted_at TIMESTAMPTZ,
    CONSTRAINT uq_role_permission UNIQUE (id_role, id_permission)
);