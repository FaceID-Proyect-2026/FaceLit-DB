CREATE TABLE environment.environment (
    id_environment UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    environment_name VARCHAR(100) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by VARCHAR(100),
    updated_at TIMESTAMPTZ,
    updated_by VARCHAR(100),
    deleted_by VARCHAR(100),
    deleted_at TIMESTAMPTZ
);

CREATE TABLE environment.chip_environment (
    id_chip_environment UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    id_chip UUID NOT NULL,
    id_environment UUID NOT NULL,
    assignment_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    state VARCHAR(20) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by VARCHAR(100),
    updated_at TIMESTAMPTZ,
    updated_by VARCHAR(100),
    deleted_by VARCHAR(100),
    deleted_at TIMESTAMPTZ
);

CREATE TABLE environment.record_environment (
    id_record_environment UUID NOT NULL PRIMARY KEY DEFAULT uuid_generate_v4(),
    id_environment UUID NOT NULL,
    id_device UUID NOT NULL,
    id_chip UUID NOT NULL,
    id_instructor_scheduled UUID NOT NULL,
    id_instructor_in_charge UUID NULL,
    entry_time TIMESTAMPTZ NOT NULL,
    registration_minutes INTEGER NOT NULL CHECK (registration_minutes > 0),
    exit_time TIMESTAMPTZ,
    shutdown_time TIMESTAMPTZ,
    exit_reminder_sent BOOLEAN NOT NULL DEFAULT FALSE,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by VARCHAR(100),
    updated_at TIMESTAMPTZ,
    updated_by VARCHAR(100),
    deleted_by VARCHAR(100),
    deleted_at TIMESTAMPTZ,
    CONSTRAINT chk_record_environment_times CHECK (
        (exit_time IS NULL AND shutdown_time IS NULL)
        OR (
            exit_time IS NOT NULL
            AND shutdown_time IS NOT NULL
            AND exit_time > entry_time
            AND shutdown_time > exit_time
        )
    )
);
