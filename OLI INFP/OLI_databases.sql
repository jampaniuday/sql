
-- DATABASES
SELECT dbname, env_status, app_name, hostname, domain
FROM
  OLI_OWNER.DATABASES d
  join OLI_OWNER.APP_DB o ON (d.licdb_id = o.licdb_id)
  JOIN OLI_OWNER.APPLICATIONS a ON (A.APP_ID = o.APP_ID)
  JOIN OLI_OWNER.DBINSTANCES i ON (d.licdb_id = i.licdb_id)
  JOIN OLI_OWNER.SERVERS s ON (i.SERVER_ID = s.server_id)
 WHERE
--    dbname like 'RDBT%'
  s.domain like 'ack-prg.csin.cz'
--  a.app_name in ('SB')
--  and domain like 'cc.csin.cz'
--  group by app_name,hostname
ORDER BY APP_NAME  ;

-- server per APP
SELECT DBNAME, hostname, app_name
FROM
  OLI_OWNER.DATABASES d
  join OLI_OWNER.APP_DB o ON (d.licdb_id = o.licdb_id)
  JOIN OLI_OWNER.APPLICATIONS a ON (A.APP_ID = o.APP_ID)
  JOIN OLI_OWNER.DBINSTANCES i ON (d.licdb_id = i.licdb_id)
  JOIN OLI_OWNER.SERVERS s ON (i.SERVER_ID = s.server_id)
 WHERE
  REGEXP_LIKE(hostname, 'z?(p)ordb[[:digit:]]+')
  --s.hostname like 'tordb03'
  --a.app_name in ('SB')
  --and domain like 'cc.csin.cz'
  --group by app_name,hostname
ORDER BY hostname, dbname  ;


-- APP_NAME info data
SELECT HOSTNAME||': '|| LISTAGG(APP_NAME,',') WITHIN GROUP (ORDER BY HOSTNAME)
FROM
(
-- innner join to remove duplicate values
SELECT hostname, app_name
      -- ,DBNAME
FROM
  OLI_OWNER.DATABASES d
  join OLI_OWNER.APP_DB o ON (d.licdb_id = o.licdb_id)
  JOIN OLI_OWNER.APPLICATIONS a ON (A.APP_ID = o.APP_ID)
  JOIN OLI_OWNER.DBINSTANCES i ON (d.licdb_id = i.licdb_id)
  JOIN OLI_OWNER.SERVERS s ON (i.SERVER_ID = s.server_id)
 WHERE s.hostname like 'tordb03'
  group by hostname, app_name, dbname
)
GROUP BY HOSTNAME ORDER by 1;

-- OLAPI_DATABASES
SELECT HOSTNAME||': '|| LISTAGG(APP_NAME,',') WITHIN GROUP (ORDER BY HOSTNAME)  from (
SELECT
  APP_NAME,
  DBNAME,
  INST_NAME,
  RAC,
  HOSTNAME, DOMAIN,
  s.FAILOVER_SERVER_ID
FROM
  OLI_OWNER.OLAPI_APPLICATIONS a
     JOIN OLI_OWNER.OLAPI_APP_DB o ON (A.APP_ID = o.APP_ID)
     JOIN OLI_OWNER.OLAPI_DATABASES d ON (o.licdb_id = d.licdb_id)
     JOIN OLI_OWNER.OLAPI_DBINSTANCES i ON (d.licdb_id = i.licdb_id)
     JOIN OLI_OWNER.OLAPI_SERVERS s ON (i.SERVER_ID = s.server_id)
WHERE
  --DBNAME in ('BRAP')
  hostname like 'tordb03'
--  hostname in ('pordb03', 'pordb04')
ORDER BY APP_NAME
) GROUP BY HOSTNAME ORDER BY 1;
;

-- update ENV status
update OLI_OWNER.DATABASES d
  set d.env_status = 'Test'
  where dbname like 'RDBT%';

--
-- INSERT do DATABASES
--

-- nahradit MERGE za OMS_DATABASES_MATCHING s match status na U
--
INSERT INTO OLI_OWNER.DATABASES (DBNAME, RAC, ENV_STATUS, DBVERSION, EM_GUID)
select DB_NAME,
       decode(dbracopt, 'YES', 'Y', 'N'),
       envstatus,
       dbversion,
       db_target_guid
  from OLI_OWNER.OMS_DATABASES_MATCHING
 WHERE match_status in ('U')
   and db_name like 'CRMED'
;
--

MERGE
 into OLI_OWNER.DATABASES oli
USING
  (select dbname, em_guid, is_rac
     from  DASHBOARD.EM_DATABASE_INFO
    where dbname like 'COLT%'
  ) em
ON (oli.dbname = em.dbname)
  when matched then
    update set oli.em_guid = em.em_guid
  WHEN NOT MATCHED THEN
    INSERT (oli.DBNAME, oli.EM_GUID, oli.RAC)
    VALUES (em.dbname, em.em_guid, em.is_rac);
;

-- run job OEM_RESYNC_TO_OLI - syncne verze, status atd.
    dbms_scheduler.run_job('OLI_OWNER.OEM_RESYNC_TO_OLI', use_current_session => TRUE);

-- INSERT do DBINSTANCES
select * from OLI_OWNER.OMS_DBINSTANCES_MATCHING
  where instance_name like 'CPT%';

INSERT INTO OLI_OWNER.DBINSTANCES (LICDB_ID, SERVER_ID, INST_NAME, EM_GUID)
SELECT
  matched_licdb_id,
  matched_server_id,
  instance_name,
  INSTANCE_TARGET_GUID
  from OLI_OWNER.OMS_DBINSTANCES_MATCHING
  where match_status in ('U')
    AND instance_name like 'CPTD%';

-- chybí ještě insert do OLI_OWNER.APP_DB
select *
FROM
  OLI_OWNER.DATABASES d
    join OLI_OWNER.APP_DB o ON (d.licdb_id = o.licdb_id)
    JOIN OLI_OWNER.APPLICATIONS a ON (A.APP_ID = o.APP_ID)
    JOIN OLI_OWNER.DBINSTANCES i ON (d.licdb_id = i.licdb_id)
  where d.dbname like 'CPTDA'
--  licdb_id = 6367
;

MERGE
 into OLI_OWNER.APP_DB d
USING
   (select d.licdb_id, a.app_id
    FROM
      OLI_OWNER.DATABASES d, OLI_OWNER.APPLICATIONS a
        where d.dbname   like 'CPTDA'
          and a.app_name like 'CPT'
    ) s
ON (s.licdb_id = d.licdb_id AND s.app_id = d.app_id)
  WHEN NOT MATCHED THEN
    INSERT (d.licdb_id, d.app_id)
    VALUES (s.licdb_id, s.app_id);
;
