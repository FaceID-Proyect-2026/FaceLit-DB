CREATE TABLE notification.notification (
    id_notification UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    id_user_app UUID NOT NULL,
    id_facial_event UUID NULL,
    notification_type VARCHAR(60) NOT NULL DEFAULT 'academic_delete_blocked',
    category VARCHAR(30) NOT NULL CHECK (category IN ('SEGURIDAD', 'ACADEMICO', 'ASISTENCIA', 'RECONOCIMIENTO_FACIAL', 'TRASLADO')),
    title VARCHAR(120) NOT NULL DEFAULT 'Notificacion',
    message TEXT NOT NULL,
    channel VARCHAR(15) NOT NULL CHECK (channel IN ('APP', 'APP_EMAIL')),
    read_status BOOLEAN NOT NULL DEFAULT FALSE, -- Indica si el usuario ya leyo la notificacion.
    read_at TIMESTAMPTZ, -- Fecha y hora en que se leyo la notificacion.
    reference_entity VARCHAR(50), -- Nombre de la entidad relacionada con la notificacion.
    reference_id UUID, -- Identificador del registro relacionado con la notificacion.
    metadata_json TEXT, -- Datos adicionales de la notificacion en formato JSON.
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW() -- Fecha y hora de creacion de la notificacion.
);

CREATE TABLE notification.email_log (
    id_email_log UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    id_notification UUID NOT NULL,
    send_status VARCHAR(20) NOT NULL CHECK (send_status IN ('PENDING', 'SENT', 'FAILED')),
    attempts INTEGER NOT NULL DEFAULT 0, -- Cantidad de intentos de envio del correo.
    sent_at TIMESTAMPTZ, -- Fecha y hora en que se envio el correo.
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_email_log_notification UNIQUE (id_notification)
);
