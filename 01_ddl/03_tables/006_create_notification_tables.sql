CREATE TABLE notification.notification (
    id_notification UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    id_user_app UUID NOT NULL,
    id_facial_event UUID NULL,
    category VARCHAR(30) NOT NULL CHECK (category IN ('SEGURIDAD', 'ACADEMICO', 'ASISTENCIA', 'RECONOCIMIENTO_FACIAL', 'TRASLADO')),
    message TEXT NOT NULL,
    channel VARCHAR(15) NOT NULL CHECK (channel IN ('APP', 'APP_EMAIL')),
    read_status BOOLEAN NOT NULL DEFAULT FALSE,
    read_at TIMESTAMPTZ,
    reference_entity VARCHAR(50), reference_id UUID,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE notification.email_log (
    id_email_log UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    id_notification UUID NOT NULL,
    send_status VARCHAR(20) NOT NULL CHECK (send_status IN ('PENDING', 'SENT', 'FAILED')),
    attempts INTEGER NOT NULL DEFAULT 0,
    sent_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_email_log_notification UNIQUE (id_notification)
);
