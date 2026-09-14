CREATE UNIQUE INDEX uq_user_chip_active ON security.user_chip (id_user_app) WHERE state = 'ACTIVE';
CREATE INDEX idx_user_chip_chip ON security.user_chip (id_chip);
