CREATE TABLE academic.program (
    id_program UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    program_name VARCHAR(100) NOT NULL UNIQUE,
    program_code VARCHAR(15) NOT NULL UNIQUE,
    state VARCHAR(20) NOT NULL,
    deactivation_reason VARCHAR(200), -- Motivo por el que se desactiva el programa.
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
    instructor_type VARCHAR(20) NOT NULL CHECK (instructor_type IN ('SPECIFIC', 'CROSS-CUTTING')), -- Tipo de instructor: SPECIFIC = especifico; CROSS-CUTTING = transversal.
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
    entity_name VARCHAR(50) NOT NULL, -- Nombre de la entidad en la que se realizo el cambio.
    entity_id UUID NOT NULL, -- Identificador del registro que se modifico.
    field_name VARCHAR(100) NOT NULL, -- Nombre del campo que se modifico.
    old_value TEXT, -- Valor que tenia el campo antes del cambio.
    new_value TEXT, -- Valor que tiene el campo despues del cambio.
    action VARCHAR(20) NOT NULL CHECK (action IN ('CREATE', 'UPDATE', 'DEACTIVATE', 'REACTIVATE', 'DELETE', 'CSV_LOAD', 'CSV_CONFIRM', 'CSV_CANCEL')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by VARCHAR(100)
);

CREATE TABLE academic.chip (
    id_chip UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    id_program UUID NOT NULL,
    chip_code VARCHAR(20) NOT NULL UNIQUE,
    start_date DATE, -- Fecha de inicio de la ficha.
    end_date DATE, -- Fecha de finalizacion de la ficha.
    state VARCHAR(20) NOT NULL,
    deactivation_reason VARCHAR(200),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by VARCHAR(100),
    updated_at TIMESTAMPTZ,
    updated_by VARCHAR(100),
    deleted_by VARCHAR(100),
    deleted_at TIMESTAMPTZ
);

CREATE TABLE academic.instructor_chip (
    id_instructor_chip UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    id_instructor UUID NOT NULL,
    id_chip UUID NOT NULL,
    assignment_start DATE, -- Fecha de inicio de la asignacion del instructor a la ficha.
    assignment_end DATE, -- Fecha de finalizacion de la asignacion del instructor a la ficha.
    active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by VARCHAR(100),
    updated_at TIMESTAMPTZ,
    updated_by VARCHAR(100),
    deleted_by VARCHAR(100),
    deleted_at TIMESTAMPTZ
);

CREATE TABLE academic.apprentice (
    id_apprentice UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    id_user_app UUID NOT NULL UNIQUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by VARCHAR(100),
    updated_at TIMESTAMPTZ,
    updated_by VARCHAR(100),
    deleted_by VARCHAR(100),
    deleted_at TIMESTAMPTZ
);

CREATE TABLE academic.apprentice_chip (
    id_apprentice_chip UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    id_apprentice UUID NOT NULL,
    id_chip UUID NOT NULL,
    state VARCHAR(20) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by VARCHAR(100),
    updated_at TIMESTAMPTZ,
    updated_by VARCHAR(100),
    deleted_by VARCHAR(100),
    deleted_at TIMESTAMPTZ
);

-- Guarda propuestas de traslado de ficha detectadas durante una carga de archivo CSV.
-- Permite revisar cada propuesta y registrar si se acepta o se cancela.
-- Ejemplo: el usuario esta en la ficha A y el CSV propone la ficha B; se guarda el traslado pendiente.
CREATE TABLE academic.csv_pending_transfer (
    id_pending_transfer UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    id_user_app UUID NOT NULL REFERENCES security.user_app(id_user_app), -- Usuario para el que se propone el traslado.
    id_chip_current UUID NOT NULL REFERENCES academic.chip(id_chip), -- Ficha actual del usuario.
    id_chip_proposed UUID NOT NULL REFERENCES academic.chip(id_chip), -- Ficha de destino propuesta por el CSV.
    source_row_number INTEGER NOT NULL, -- Numero de fila del CSV que origino la propuesta.
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING', -- Estado: PENDING = pendiente; ACCEPTED = aceptado; CANCELLED = cancelado.
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by VARCHAR(100),
    updated_at TIMESTAMPTZ,
    updated_by VARCHAR(100),
    deleted_by VARCHAR(100),
    deleted_at TIMESTAMPTZ,
    resolved_at TIMESTAMPTZ, -- Fecha y hora en que se acepto o cancelo la propuesta.
    resolved_by VARCHAR(100), -- Quien acepto o cancelo la propuesta.
    CONSTRAINT chk_csv_pending_transfer_status CHECK (status IN ('PENDING', 'ACCEPTED', 'CANCELLED'))
);

-- Evita que un mismo usuario tenga mas de un traslado pendiente al mismo tiempo.
CREATE UNIQUE INDEX uq_pending_transfer_active
ON academic.csv_pending_transfer (id_user_app)
WHERE status = 'PENDING';
