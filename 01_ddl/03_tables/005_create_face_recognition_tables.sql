CREATE TABLE facialrecognition.device (
    id_device UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    device_code VARCHAR(50) NOT NULL,
    location VARCHAR(100),
    status VARCHAR(20) NOT NULL CHECK (status IN ('ACTIVE', 'PENDING', 'INACTIVE')),
    origin_ip VARCHAR(50),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by VARCHAR(100),
    updated_at TIMESTAMPTZ,
    updated_by VARCHAR(100),
    deleted_by VARCHAR(100),
    deleted_at TIMESTAMPTZ
);

CREATE TABLE facialrecognition.user_face (
    id_user_face UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    id_user_app UUID NOT NULL,
    biometric_vector BYTEA NOT NULL,
    registration_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    status VARCHAR(50) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by VARCHAR(100),
    updated_at TIMESTAMPTZ,
    updated_by VARCHAR(100),
    deleted_by VARCHAR(100),
    deleted_at TIMESTAMPTZ
);

CREATE TABLE facialrecognition.facial_event (
    id_facial_event UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    id_user_app UUID NULL,
    id_record_environment UUID NOT NULL,
    id_device UUID NOT NULL,
    event_datetime TIMESTAMPTZ NOT NULL,
    event_type VARCHAR(20) NOT NULL CHECK (event_type IN ('ENTRADA', 'SALIDA')),
    recognition_result VARCHAR(20) NOT NULL,
    send_status VARCHAR(20) NOT NULL,
    origin VARCHAR(10) NOT NULL CHECK (origin IN ('PC', 'MOBILE')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by VARCHAR(100),
    updated_at TIMESTAMPTZ,
    updated_by VARCHAR(100),
    deleted_by VARCHAR(100),
    deleted_at TIMESTAMPTZ
);

CREATE TABLE facialrecognition.biometric_log (
    id_biometric_log UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    id_facial_event UUID NOT NULL,
    description TEXT,
    log_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by VARCHAR(100),
    updated_at TIMESTAMPTZ,
    updated_by VARCHAR(100),
    deleted_by VARCHAR(100),
    deleted_at TIMESTAMPTZ
);

CREATE TABLE facialrecognition.face_reset_request (
    id_face_reset_request UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    id_user_app UUID NOT NULL,
    request_status VARCHAR(20) NOT NULL CHECK (request_status IN ('PENDING', 'ACCEPTED', 'REJECTED')),
    requested_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    resolved_by UUID,
    resolved_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), created_by VARCHAR(100), updated_at TIMESTAMPTZ, updated_by VARCHAR(100), deleted_by VARCHAR(100), deleted_at TIMESTAMPTZ
);
