--
-- SYNONYM
--
CREATE OR REPLACE SYNONYM "CLONING_OWNER"."MGMT$DB_DBNINSTANCEINFO"
  FOR "DASHBOARD"."MGMT$DB_DBNINSTANCEINFO";
CREATE OR REPLACE SYNONYM "CLONING_OWNER"."MGMT$DB_INIT_PARAMS"
  FOR "DASHBOARD"."MGMT$DB_INIT_PARAMS";
CREATE OR REPLACE SYNONYM "CLONING_OWNER"."CM$MGMT_ASM_CLIENT_ECM"
  FOR "DASHBOARD"."CM$MGMT_ASM_CLIENT_ECM";

--
-- VIEW
--
create or replace view cloning_owner.cloning_databases
AS
      SELECT
        s.dbname source_dbname,
        s.licdb_id source_licdb_id,
        s.rac source_is_rac_yn,
        t.dbname target_dbname,
        t.licdb_id target_licdb_id,
        t.rac p_target_is_rac_yn,
        t.env_status target_env_status,
        m.method_name
      FROM oli_owner.databases t
           JOIN oli_owner.databases s ON t.clone_source_licdb_id= s.licdb_id
           JOIN cloning_method m ON t.cloning_method_id    = m.cloning_method_id
      WHERE 1=1
;

-- pipelined type - jde jen špatně přepsat vo selecktu ...

-- data
REM INSERTING into CLONING_METHOD
SET DEFINE OFF;
Insert into CLONING_METHOD values ('1','RMAN_DUPLICATE','Duplikace RMAN - do GUI','vykecavaci');
Insert into CLONING_METHOD values ('2','HITACHI1','Pole HITACHI metoda 1','vykecavaci');
Insert into CLONING_METHOD values ('3','SNAPVX','Pole VMAX3 přes SnapVX snapshoty','vykecavaci');
Insert into CLONING_METHOD values ('-999','COMMON','Obecna metoda pro obecne parametry','vykecavaci');


REM INSERTING into CLONING_METHOD_STEP
SET DEFINE OFF;
Insert into CLONING_METHOD_STEP values ('3','STEP001_prepare.sh','1','Desc','Y','N');
Insert into CLONING_METHOD_STEP values ('3','STEP010_shutdown_db.sh','10','Desc','Y','N');
Insert into CLONING_METHOD_STEP values ('3','STEP020_umount_asm_dg.sh','20','Desc','Y','N');
Insert into CLONING_METHOD_STEP values ('3','STEP100_create_disk_snapshot.sh','100','Desc','N','Y');
Insert into CLONING_METHOD_STEP values ('3','STEP109_mount_asm_dg.sh','109','Desc','Y','N');
Insert into CLONING_METHOD_STEP values ('3','STEP110_recover_clone_db.sh','110','Desc','Y','N');
Insert into CLONING_METHOD_STEP values ('3','STEP120_rename_clone_db.sh','120','Desc','Y','N');
Insert into CLONING_METHOD_STEP values ('3','STEP130_rename_clone_asmdg.sh','130','Desc','Y','N');
Insert into CLONING_METHOD_STEP values ('3','STEP140_password_file.sh','140','Desc','Y','N');
Insert into CLONING_METHOD_STEP values ('3','STEP180_rac_drop_unused_redo_thread.sh','180','Desc','Y','N');
Insert into CLONING_METHOD_STEP values ('3','STEP205_emcli_stop_blackout.sh','205','Desc','Y','N');
Insert into CLONING_METHOD_STEP values ('3','STEP210_rman_reset_config.sh','210','Desc','Y','N');
Insert into CLONING_METHOD_STEP values ('3','STEP220_rman_resync.sh','220','Desc','Y','N');
Insert into CLONING_METHOD_STEP values ('3','STEP300_app_sql_scripts.sh','300','Desc','Y','N');
Insert into CLONING_METHOD_STEP values ('3','STEP310_grant_dba.sh','310','Desc','Y','N');
Insert into CLONING_METHOD_STEP values ('3','STEP400_arm_audit.sh','400','Desc','Y','Y');
Insert into CLONING_METHOD_STEP values ('3','STEP005_pre_sql_scripts.sh','5','Desc','Y','N');
Insert into CLONING_METHOD_STEP values ('3','STEP230_rman_backup_validate.sh','230','Desc','Y','N');
Insert into CLONING_METHOD_STEP values ('3','STEP320_autoextend_on.sh','320','Desc','Y','N');