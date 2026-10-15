DO $$
DECLARE item record;
BEGIN
    FOR item IN SELECT conname FROM pg_constraint
        WHERE conrelid = 'notification.notification'::regclass AND contype = 'c'
          AND pg_get_constraintdef(oid) LIKE '%channel%'
    LOOP
        EXECUTE format('ALTER TABLE notification.notification DROP CONSTRAINT %I', item.conname);
    END LOOP;
    ALTER TABLE notification.notification ADD CONSTRAINT notification_channel_check CHECK (channel IN ('APP', 'APP_EMAIL', 'EMAIL'));
    FOR item IN SELECT conname FROM pg_constraint
        WHERE conrelid = 'notification.email_log'::regclass AND contype = 'c'
          AND pg_get_constraintdef(oid) LIKE '%send_status%'
    LOOP
        EXECUTE format('ALTER TABLE notification.email_log DROP CONSTRAINT %I', item.conname);
    END LOOP;
    ALTER TABLE notification.email_log ADD CONSTRAINT email_log_send_status_check CHECK (send_status IN ('PENDING', 'SENT', 'FAILED', 'CANCELLED'));
END $$;

UPDATE notification.notification SET channel = 'EMAIL' WHERE notification_type = 'attendance_exit_reminder';
