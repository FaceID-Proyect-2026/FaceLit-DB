GRANT USAGE ON SCHEMA facialrecognition TO facelit_micro_facial;

GRANT SELECT, INSERT, UPDATE
ON facialrecognition.user_face
TO facelit_micro_facial;

GRANT SELECT (
    id_face_reset_request,
    id_user_app,
    authorization_token,
    request_status,
    consumed_at,
    authorization_expires_at,
    deleted_at
)
ON facialrecognition.face_reset_request
TO facelit_micro_facial;

GRANT UPDATE (consumed_at, updated_at, updated_by)
ON facialrecognition.face_reset_request
TO facelit_micro_facial;
