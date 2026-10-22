-- Additive: existing credentials, recovery codes and notification history are preserved.
CREATE TABLE security.account_access_request (
    id uuid PRIMARY KEY,
    id_user_app uuid NOT NULL REFERENCES security.user_app(id_user_app),
    purpose varchar(255) NOT NULL CHECK (purpose IN ('WELCOME', 'EMAIL_CHANGE')),
    target_email varchar(255) NOT NULL,
    original_email varchar(255) NOT NULL,
    token_hash varchar(64) UNIQUE,
    expires_at timestamptz,
    used boolean NOT NULL DEFAULT false,
    send_status varchar(255) NOT NULL DEFAULT 'PENDING',
    attempts integer NOT NULL DEFAULT 0,
    last_error varchar(255),
    created_at timestamptz NOT NULL DEFAULT now(),
    last_attempt_at timestamptz
);
CREATE INDEX idx_account_access_user ON security.account_access_request(id_user_app);
CREATE INDEX idx_account_access_delivery ON security.account_access_request(send_status) WHERE used = false;
CREATE UNIQUE INDEX uk_account_access_pending_user ON security.account_access_request(id_user_app) WHERE used = false;
