--------------------------------------------------------
--  DDL for Table GSSERIES_SPEC
--------------------------------------------------------

  CREATE TABLE "GROUNDFISH"."GSSERIES_SPEC" 
   (	"PK_SERIES_ID" VARCHAR2(16 BYTE), 
	"FK_SOURCE_ID" VARCHAR2(16 BYTE), 
	"FK_DATASET_ID" VARCHAR2(16 BYTE), 
	"DESCRIPTION" VARCHAR2(100 BYTE), 
	"AREA_SURVEYED" VARCHAR2(16 BYTE), 
	"MINSTRAT" VARCHAR2(4 BYTE), 
	"MAXSTRAT" VARCHAR2(4 BYTE), 
	"SMONTH" NUMBER(4,0), 
	"EMONTH" NUMBER(4,0), 
	"SYEAR" NUMBER(4,0), 
	"EYEAR" NUMBER(4,0), 
	"SRS" NUMBER(10,8), 
	"REG" NUMBER(10,8), 
	"COMP" NUMBER(10,8), 
	"TAG" NUMBER(10,8), 
	"GEAR" NUMBER(10,8), 
	"EXPLOR" NUMBER(10,8), 
	"TYPE_RANK" VARCHAR2(30 BYTE), 
	"NSETS" NUMBER(4,0), 
	"NMISSION" NUMBER(4,0), 
	"STD_TOW_LEN" NUMBER(8,4), 
	"STD_WING_SIZE" NUMBER(8,4), 
	"TRADITIONAL_NAME" VARCHAR2(30 BYTE)
   ) PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 NOCOMPRESS LOGGING
  STORAGE(INITIAL 65536 NEXT 65536 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1 BUFFER_POOL DEFAULT)
  TABLESPACE "MFD_GROUNDFISH" ;
  GRANT SELECT ON "GROUNDFISH"."GSSERIES_SPEC" TO "MFLIB";
 
  GRANT INSERT ON "GROUNDFISH"."GSSERIES_SPEC" TO "BRANTON";
 
  GRANT SELECT ON "GROUNDFISH"."GSSERIES_SPEC" TO "BRANTON";
 
  GRANT UPDATE ON "GROUNDFISH"."GSSERIES_SPEC" TO "BRANTON";
 
  GRANT SELECT ON "GROUNDFISH"."GSSERIES_SPEC" TO "ABUNDY";
 
  GRANT SELECT ON "GROUNDFISH"."GSSERIES_SPEC" TO "RICARDD";
 
  GRANT SELECT ON "GROUNDFISH"."GSSERIES_SPEC" TO "HUBLEYB";
 
  GRANT SELECT ON "GROUNDFISH"."GSSERIES_SPEC" TO "GREYSONP";