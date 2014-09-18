--------------------------------------------------------
--  DDL for Table GSMVINF_DUMMY
--------------------------------------------------------

  CREATE TABLE "GROUNDFISH"."GSMVINF_DUMMY" 
   (	"MISSION" VARCHAR2(10 BYTE), 
	"SDATE" DATE, 
	"EDATE" DATE, 
	"STRAT" VARCHAR2(3 BYTE), 
	"TYPE" NUMBER
   ) PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 NOCOMPRESS LOGGING
  STORAGE(INITIAL 16384 NEXT 65536 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1 BUFFER_POOL DEFAULT)
  TABLESPACE "MFD_GROUNDFISH" ;
  GRANT SELECT ON "GROUNDFISH"."GSMVINF_DUMMY" TO "RICARDD";
 
  GRANT SELECT ON "GROUNDFISH"."GSMVINF_DUMMY" TO "HUBLEYB";
 
  GRANT SELECT ON "GROUNDFISH"."GSMVINF_DUMMY" TO "GREYSONP";