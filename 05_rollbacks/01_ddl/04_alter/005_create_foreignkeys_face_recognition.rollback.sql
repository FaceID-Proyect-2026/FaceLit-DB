ALTER TABLE facialrecognition.biometric_log DROP CONSTRAINT IF EXISTS fk_biometric_log_event;
ALTER TABLE facialrecognition.face_reset_request DROP CONSTRAINT IF EXISTS fk_face_reset_request_resolver;
ALTER TABLE facialrecognition.face_reset_request DROP CONSTRAINT IF EXISTS fk_face_reset_request_user;
ALTER TABLE facialrecognition.facial_event DROP CONSTRAINT IF EXISTS fk_facial_event_device;
ALTER TABLE facialrecognition.facial_event DROP CONSTRAINT IF EXISTS fk_facial_event_record_environment;
ALTER TABLE facialrecognition.facial_event DROP CONSTRAINT IF EXISTS fk_facial_event_user;
ALTER TABLE facialrecognition.user_face DROP CONSTRAINT IF EXISTS fk_user_face_user;
