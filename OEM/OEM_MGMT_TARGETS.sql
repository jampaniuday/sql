--
-- mgmt_targets
-- mgmt_target_properties
--

-- ALL targets
SELECT
--  t.*
  t.target_name
  ||':'|| t.target_type
--  ,t.category_prop_1
  ,T.Host_Name
FROM
  MGMT_TARGETS t
 WHERE
   t.target_type IN ('oracle_database','rac_database')
--   t.target_type IN ('host')
   AND t.target_name like 'APS%'
--   AND category_prop_1 in ('HP-UX','AIX')
--    AND category_prop_1 in ('Linux','HP-UX','AIX')
   -- filtr na produkci
   --AND target_guid IN (SELECT TARGET_GUID FROM SYSMAN.MGMT$GROUP_MEMBERS WHERE group_name = 'PRODUKCE')
   -- bez Postgresu
   --and NOT (host_name like 'ppg%' or host_name like 'lintr%' or host_name like '%avlog%')
   --
ORDER BY t.target_name;

-- DB targets
select database_name,
       target_name,
       host_name
  FROM MGMT$DB_DBNINSTANCEINFO d
ORDER by d.target_name;

-- count db
select count(*)
  from MGMT_TARGETS t
WHERE
  t.target_type IN ('oracle_database','rac_database')  ;

-- DB Instances
 select DB_TARGET_GUID,db_name,dbversion,nvl(dbracopt,'NO') dbracopt,envStatus,contact, department, comment_text from (
        SELECT target_guid DB_TARGET_GUID, target_type, property_value,property_name
             FROM MGMT$TARGET_PROPERTIES
             WHERE target_type in ('rac_database','oracle_database')
      )
      PIVOT (MIN(PROPERTY_VALUE) FOR PROPERTY_NAME IN ('DBName' as db_name,
                                                       'DBVersion' as dbversion,
                                                       'RACOption' as dbracopt,
                                                       'orcl_gtp_lifecycle_status' as envStatus,
                                                       'orcl_gtp_contact' as contact,
                                                       'orcl_gtp_department' as department,
                                                       'orcl_gtp_comment' as comment_text))
   where ((target_type='rac_database' and nvl(dbracopt,'NO')='YES')
          or (target_type='oracle_database' and nvl(dbracopt,'NO')='NO'))
  ;


-- DB per verze a per OS verze
select t.category_prop_1, s.category_prop_1 || ' ' || s.category_prop_2, count(*)
  from MGMT_TARGETS t inner join MGMT_TARGETS s ON (t.host_name = s.target_name)
WHERE
  t.target_type IN ('oracle_database','rac_database')
  --and t.target_name like 'MCIP%'
  --and t.category_prop_1 <> ''
group by t.category_prop_1, s.category_prop_1 || ' ' || s.category_prop_2
order by 1,2;

-- OEM Groups and members
SELECT
    AGGREGATE_TARGET_NAME "GROUP",
    member_target_name "SERVER"
    --member_target_type
  FROM
    MGMT$TARGET_FLAT_MEMBERS
  WHERE
    MEMBER_TARGET_TYPE  IN ('host')
    --AND AGGREGATE_TARGET_NAME IN ('PRODUKCE')
    AND MEMBER_TARGET_NAME like 'dordb04%'
;

-- OEM connect string
  -- single instance, hostname z MachineName
    select t.target_guid,
       t.target_name,
       --target_name, target_type, host_name,
       machine.property_value hostname
       from MGMT$TARGET t
       JOIN MGMT$TARGET_PROPERTIES machine on (t.TARGET_GUID=machine.TARGET_GUID) -- machine
       where t.type_qualifier3     = 'DB'
       and   t.target_type         = 'oracle_database'
       AND   machine.PROPERTY_NAME = 'MachineName'
    UNION ALL
    -- RAC, hostname ze scanName
    select t.target_guid,
       t.target_name,
       --t.target_name, t.target_type,
       c.hostname
     from   MGMT$TARGET t
       JOIN MGMT$TARGET_PROPERTIES dp ON (t.TARGET_GUID=dp.TARGET_GUID)
       JOIN (
          SELECT t.target_name cluster_name,
          c.Property_Value hostname
     FROM
       MGMT$TARGET t JOIN MGMT$TARGET_PROPERTIES c
         ON (t.TARGET_GUID=c.TARGET_GUID)
  WHERE
          t.target_type   = 'cluster'
      AND c.property_name = 'scanName'
      ) c ON (dp.Property_Value = c.cluster_name)
       where t.type_qualifier3 = 'DB'
       and t.target_type = 'rac_database'
       and dp.property_name = 'ClusterName'
;
-- DB version report
SELECT
  p.target_name,
  t.host_name,
  p.property_name,
  p.property_value --"DBVersion"
  --, t.category_prop_1
  --t.*
FROM mgmt$target_properties p join MGMT_TARGETS t on (t.TARGET_GUID = p.target_guid)
WHERE --t.target_type IN ('oracle_database')
      t.target_type IN ('oracle_database','rac_database')
  AND   p.property_name = 'Version'
  --AND p.target_name in('SK1O','SK2O','CRMRA','MCISTA','BRAEA','CPSEA','DMSLAPTS')
--  AND p.property_value LIKE '11.1%'
ORDER BY upper(t.target_name) ;

-- OS info/HW info short AIX/Linux/Win ..
select * from MGMT$OS_HW_SUMMARY  ;
select * from sysman.MGMT_ECM_HW;

-- OS info - replacement for short info version
select target_name,
       case
         when category_prop_1 like 'AIX' then category_prop_1||' '||substr(category_prop_2,1,3)
         when category_prop_1 like 'HP-UX' then category_prop_1||' '||substr(category_prop_2,3)
         when category_prop_1 like 'Linux' then replace(category_prop_2, 'Red Hat Enterprise Linux Server release','RHEL')
         when category_prop_1 like 'Windows' then category_prop_2
         else category_prop_1||' '||category_prop_2
       end  "OS"
  from SYSMAN.MGMT_TARGETS
 where target_type = 'host'
-- and target_name like 'aspspkidb1%'
-- and target_name <> host_name
 order by target_name
;

-- Platforms
select
  category_prop_1, count(*)
  from SYSMAN.MGMT_TARGETS
   where target_type IN ('oracle_database','rac_database')
group by CATEGORY_PROP_1 order by 2 desc;

-- Versions
select
  category_prop_1, count(*)
  from SYSMAN.MGMT_TARGETS
--   where target_type = 'host'
group by CATEGORY_PROP_1 order by 2 desc;


-- OS info MEM AIX
with db_count as (
select host_name, count(*) cnt
  from MGMT_TARGETS t
 where category_prop_3 = 'DB'
 group by host_name
 )
select d.host_name, mem, cnt "#db", 16384*cnt
  from db_count d
    join MGMT$OS_HW_SUMMARY h on (d.host_name = h.host_name)
where h.MA like 'PowerPC%'
 and 16384*cnt > mem
 order by host_name
 ;

-- Contacts / LifeCycle status
-- Kontakty per Linux DB farma
select --p.*,
  --p.target_name, p.property_value "Contact"
  p.target_name||': '||p.property_value
 from mgmt$target_properties p
where 1=1
  and p.target_type in ('rac_database','oracle_database')
  and p.property_name = 'orcl_gtp_contact'  -- Contact
  --and property_name = 'orcl_gtp_lifecycle_status' -- Lifecycle status
  -- and property_name = 'OracleHome'  -- OracleHome
  and p.target_guid in (
  SELECT TARGET_GUID
    FROM MGMT_TARGETS
    WHERE target_type LIKE '%database'
      AND host_name LIKE 'pordb02.vs.csin.cz'
  )
order by upper(p.target_name);

--// pouze DB v�etn� RAC, ale bez RAC instanc� //--
SELECT target_name,
	   case when emd_url like '%cc.csin.cz%' then 'VIE' else 'PRG' end DC
  FROM SYSMAN.mgmt_targets
 WHERE category_prop_3 = 'DB'
order by 1;

-- pouze produkce
SELECT count(*)
    --member_target_name,
    --member_target_type
  FROM
    MGMT$TARGET_FLAT_MEMBERS
  WHERE
    AGGREGATE_TARGET_NAME IN ('PRODUKCE')
  AND MEMBER_TARGET_TYPE  IN ('oracle_database','rac_database')
  --ORDER BY  member_target_name
  ;