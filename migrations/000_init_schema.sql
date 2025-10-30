-- ATLAS Investment Demo — initialization banner
-- (LiveSQL runs in your schema; no CREATE USER here)
-- Keep session NLS/date formats predictable for demos.
ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD';

-- Drop objects safely if they already exist (idempotent-ish in LiveSQL)
BEGIN
  FOR r IN (SELECT object_name, object_type
              FROM user_objects
             WHERE object_type IN ('TABLE','VIEW','SEQUENCE','PACKAGE','PACKAGE BODY','INDEX')
               AND object_name LIKE 'ATLAS_%')
  LOOP
    EXECUTE IMMEDIATE
      CASE r.object_type
        WHEN 'TABLE' THEN 'DROP TABLE '||r.object_name||' CASCADE CONSTRAINTS'
        WHEN 'VIEW'  THEN 'DROP VIEW ' ||r.object_name
        WHEN 'INDEX' THEN 'DROP INDEX '||r.object_name
        WHEN 'PACKAGE' THEN 'DROP PACKAGE '||r.object_name
        WHEN 'PACKAGE BODY' THEN 'DROP PACKAGE '||r.object_name
      END;
  END LOOP;
END;
/
