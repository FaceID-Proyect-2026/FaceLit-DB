CREATE TABLE facialrecognition.device (
    id_device UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    id_environment UUID NOT NULL,
    device_code VARCHAR(50) NOT NULL UNIQUE,
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

-- Guarda los datos del rostro del aprendiz para compararlos durante el reconocimiento facial.
-- El embedding representa rasgos del rostro mediante numeros; no es la fotografia.
CREATE TABLE facialrecognition.user_face (
    id_user_face UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    id_apprentice UUID NOT NULL UNIQUE,
    embedding vector NOT NULL, -- Vector numerico que representa el rostro y permite compararlo con otros rostros.
    embedding_dimension INT4, -- Cantidad de componentes numericos que tiene el vector del rostro.
    model_name VARCHAR(100), -- Nombre del modelo de reconocimiento facial que genero el vector.
    photo_reference VARCHAR(500), -- Ruta, URL o identificador de la foto de referencia; no guarda la imagen en este campo.
    status VARCHAR(20) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by VARCHAR(1000),
    updated_at TIMESTAMPTZ,
    updated_by VARCHAR(100),
    deleted_by VARCHAR(100),
    deleted_at TIMESTAMPTZ
);

CREATE TABLE facialrecognition.facial_event (
    id_facial_event UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    id_record_environment UUID NOT NULL, 
    id_device UUID NOT NULL,
    id_apprentice UUID NOT NULL,
    event_datetime TIMESTAMPTZ NOT NULL, -- Fecha y hora en que ocurrio el evento facial.
    event_type VARCHAR(20) NOT NULL CHECK (event_type IN ('ENTRY', 'EXIT')), -- Tipo de evento: ENTRY = entrada; EXIT = salida.
    recognition_result VARCHAR(20) NOT NULL, -- Resultado obtenido al intentar reconocer el rostro.
    attendance_status VARCHAR(20) NOT NULL CHECK (attendance_status IN ('PUNCTUAL', 'LATE', 'ABSENT')), -- Estado de asistencia: PUNCTUAL = puntual; LATE = tarde; ABSENT = ausente.
    match_score NUMERIC(5,4) CHECK (match_score >= 0 AND match_score <= 1), -- Puntaje de coincidencia facial entre 0 y 1; no equivale necesariamente a una probabilidad.
    origin VARCHAR(10) NOT NULL CHECK (origin IN ('PC', 'MOBILE')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by VARCHAR(100),
    updated_at TIMESTAMPTZ,
    updated_by VARCHAR(100),
    deleted_by VARCHAR(100),
    deleted_at TIMESTAMPTZ
);

-- Bitacora que guarda descripciones asociadas a un evento facial para facilitar su seguimiento y revision.
-- Cada registro se relaciona con un evento mediante id_facial_event.
CREATE TABLE facialrecognition.biometric_log (
    id_biometric_log UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    id_facial_event UUID NOT NULL,
    description TEXT,
    log_date TIMESTAMPTZ NOT NULL DEFAULT NOW(), -- Fecha y hora de la anotacion en la bitacora; por defecto, el momento actual.
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by VARCHAR(100),
    updated_at TIMESTAMPTZ,
    updated_by VARCHAR(100),
    deleted_by VARCHAR(100),
    deleted_at TIMESTAMPTZ
);

-- Registra solicitudes para restablecer el registro facial de un usuario.
-- Permite guardar si la solicitud esta pendiente, fue aceptada o fue rechazada, y quien la resolvio.
-- La tabla conserva la solicitud; el restablecimiento del rostro lo realiza la logica de la aplicacion.
CREATE TABLE facialrecognition.face_reset_request (
    id_face_reset_request UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    id_user_app UUID NOT NULL,
    request_status VARCHAR(20) NOT NULL CHECK (request_status IN ('PENDING', 'ACCEPTED', 'REJECTED')), -- Estado: PENDING = pendiente; ACCEPTED = aceptada; REJECTED = rechazada.
    requested_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), -- Fecha y hora en que se realizo la solicitud.
    resolved_by UUID, -- Identificador de quien acepto o rechazo la solicitud.
    resolved_at TIMESTAMPTZ, -- Fecha y hora en que se acepto o rechazo la solicitud.
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by VARCHAR(100),
    updated_at TIMESTAMPTZ,
    updated_by VARCHAR(100),
    deleted_by VARCHAR(100),
    deleted_at TIMESTAMPTZ
);
