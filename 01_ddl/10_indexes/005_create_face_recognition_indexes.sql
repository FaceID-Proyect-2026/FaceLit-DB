CREATE UNIQUE INDEX uq_user_face_active ON facialrecognition.user_face (id_user_app) WHERE status = 'ACTIVE';
CREATE UNIQUE INDEX uq_face_reset_request_pending ON facialrecognition.face_reset_request (id_user_app) WHERE request_status = 'PENDING';
CREATE INDEX idx_facial_event_session ON facialrecognition.facial_event (id_record_environment, event_datetime);
CREATE INDEX idx_facial_event_user ON facialrecognition.facial_event (id_user_app);
