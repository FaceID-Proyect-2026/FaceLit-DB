ALTER TABLE legal.terms_acceptance ADD CONSTRAINT fk_terms_acceptance_user FOREIGN KEY (id_user_app) REFERENCES security.user_app(id_user_app);
