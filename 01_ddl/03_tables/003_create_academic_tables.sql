CREATE TABLE academic.program (
    id_program UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    program_name VARCHAR(100) NOT NULL UNIQUE,
    program_code VARCHAR(15) NOT NULL UNIQUE,
    state VARCHAR(20) NOT NULL,
    deactivation_reason VARCHAR(200),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by VARCHAR(100),
    updated_at TIMESTAMPTZ,
    updated_by VARCHAR(100),
    deleted_by VARCHAR(100),
    deleted_at TIMESTAMPTZ
);

CREATE TABLE academic.instructor (
    id_instructor UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    id_user_app UUID NOT NULL UNIQUE,
    instructor_type VARCHAR(20) NOT NULL CHECK (instructor_type IN ('ESPECIFICO', 'TRANSVERSAL')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by VARCHAR(100), updated_at TIMESTAMPTZ, updated_by VARCHAR(100), deleted_by VARCHAR(100), deleted_at TIMESTAMPTZ
);

CREATE TABLE academic.instructor_program (
    id_instructor_program UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    id_instructor UUID NOT NULL,
    id_program UUID NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by VARCHAR(100), updated_at TIMESTAMPTZ, updated_by VARCHAR(100), deleted_by VARCHAR(100), deleted_at TIMESTAMPTZ,
    CONSTRAINT uq_instructor_program UNIQUE (id_instructor, id_program)
);

CREATE TABLE academic.change_history (
    id_change_history UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    entity_name VARCHAR(50) NOT NULL,
    entity_id UUID NOT NULL,
    field_name VARCHAR(100) NOT NULL,
    old_value TEXT,
    new_value TEXT,
    action VARCHAR(20) NOT NULL CHECK (action IN ('CREATE', 'UPDATE', 'DEACTIVATE', 'REACTIVATE', 'DELETE', 'CSV_LOAD', 'CSV_CONFIRM', 'CSV_CANCEL')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by VARCHAR(100)
);

CREATE TABLE academic.chip (
    id_chip UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    id_program UUID NOT NULL,
    chip_code VARCHAR(20) NOT NULL UNIQUE,
    state VARCHAR(20) NOT NULL,
    deactivation_reason VARCHAR(200),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by VARCHAR(100),
    updated_at TIMESTAMPTZ,
    updated_by VARCHAR(100),
    deleted_by VARCHAR(100),
    deleted_at TIMESTAMPTZ
);