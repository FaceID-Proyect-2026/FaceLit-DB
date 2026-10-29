-- The canonical column wins on INSERT (the old timestamp has a default).
-- On UPDATE, propagate whichever spelling changed; reject conflicting writes.
CREATE FUNCTION roleandpermission.sync_english_nomenclature() RETURNS trigger
LANGUAGE plpgsql AS $$
DECLARE
    legacy_name TEXT := TG_ARGV[0];
    canonical_name TEXT := TG_ARGV[1];
    incoming JSONB := to_jsonb(NEW);
    previous JSONB;
    selected_value JSONB;
BEGIN
    IF TG_OP = 'INSERT' THEN
        selected_value := COALESCE(NULLIF(incoming -> canonical_name, 'null'::jsonb),
                                   incoming -> legacy_name);
    ELSE
        previous := to_jsonb(OLD);
        IF incoming -> canonical_name IS DISTINCT FROM previous -> canonical_name THEN
            IF incoming -> legacy_name IS DISTINCT FROM previous -> legacy_name
               AND incoming -> legacy_name IS DISTINCT FROM incoming -> canonical_name THEN
                RAISE EXCEPTION 'Conflicting writes to % and %', legacy_name, canonical_name;
            END IF;
            selected_value := incoming -> canonical_name;
        ELSE
            selected_value := incoming -> legacy_name;
        END IF;
    END IF;
    NEW := jsonb_populate_record(NEW,
        jsonb_build_object(legacy_name, selected_value, canonical_name, selected_value));
    RETURN NEW;
END;
$$;

CREATE TRIGGER sync_role_name BEFORE INSERT OR UPDATE ON roleandpermission.role
FOR EACH ROW EXECUTE FUNCTION roleandpermission.sync_english_nomenclature('name_rol', 'role_name');
CREATE TRIGGER sync_permission_description BEFORE INSERT OR UPDATE ON roleandpermission.permission
FOR EACH ROW EXECUTE FUNCTION roleandpermission.sync_english_nomenclature('descripcion', 'description');
CREATE TRIGGER sync_user_role_assigned_at BEFORE INSERT OR UPDATE ON roleandpermission.user_role
FOR EACH ROW EXECUTE FUNCTION roleandpermission.sync_english_nomenclature('asigned_at', 'assigned_at');
