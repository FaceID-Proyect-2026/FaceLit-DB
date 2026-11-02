REVOKE UPDATE (consumed_at, updated_at, updated_by)
ON facialrecognition.face_reset_request
FROM facelit_micro_facial;

REVOKE SELECT (
    id_face_reset_request,
    id_user_app,
    authorization_token,
    request_status,
    consumed_at,
    authorization_expires_at,
    deleted_at
)
ON facialrecognition.face_reset_request
FROM facelit_micro_facial;

REVOKE SELECT, INSERT, UPDATE
ON facialrecognition.user_face
FROM facelit_micro_facial;

REVOKE USAGE ON SCHEMA facialrecognition FROM facelit_micro_facial;
