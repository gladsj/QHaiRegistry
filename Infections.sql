/*
**********************************************************************************************************************
*    TITLE:              Infections
*    AUTHOR:              
*    PROJECT:            Heart Failure - HF Use Case
*    DESCRIPTION:        Patient Infections history
*********************************************************************************************************************** 
* 
*  DATABASE:  Clarity 
*  VERSION CONTROL: 
*   -----------------      ----------------------------------          ------------------------------------------------ 
      DATE                       Modified By                                 Changes 
    -----------------          ----------------------------------          ------------------------------------------------ 
*
**********************************************************************************************************************
*   Restricting  Elements: 
-----------------        ----------------------------------          ------------------------------------------------ 
 Table Name              Column Name                                    DESCRIPTION
 Patients                PAT_MRN_ID                                    To filter out patient with respect to patient Id
-----------------        ----------------------------------          ------------------------------------------------ 
**********************************************************************************************************************
*  Table Used: 
--------------------------------------------------------------------------------------------------------------------- 
INFECTIONS, PAT_ENC , PATIENT, ZC_INFECTION_RECORD_TYPE,ZC_INFECTION
**********************************************************************************************************************
*/ 

-- Drive the plan from the date-filtered INFECTIONS rows first; preserve exact filtering and join semantics
WITH d AS (SELECT TRUNC(SYSDATE) AS as_of FROM dual),
i AS (
    SELECT
        i.INFECTION_ID,
        i.PAT_ID,
        i.PAT_ENC_CSN_ID,
        i.ADD_UTC_DTTM,
        i.ADD_LOCAL_DTTM,
        i.RESOLVE_UTC_DTTM,
        i.RESOLVE_LOCAL_DTTM,
        i.EXPIRATION_DATE,
        i.DOESNT_EXPIRE_YN,
        i.REVIEW_DATE,
        i.ONSET_DATE,
        i.INFECTION_RECORD_TYPE_C,
        i.INFECTION_TYPE_C,
        i.INF_STATUS_C,
        i.ADD_USER_ID,
        i.RESOLVE_USER_ID,
        i.SPECIMEN_TYPE_C,
        i.SPECIMEN_SOURCE_C,
        i.COMMENT_USER_ID,
        i.COMMENT_UTC_DTTM,
        i.COMMENTS
    FROM INFECTIONS i
    CROSS JOIN d
    WHERE i.ADD_LOCAL_DTTM_DT BETWEEN d.as_of - 365 AND d.as_of  -- identical predicate, SARGable
)
SELECT
    i.INFECTION_ID,
    p.PAT_ID,
    p.PAT_MRN_ID AS MRN,
    pe.CONTACT_DATE,
    i.PAT_ENC_CSN_ID,
    i.ADD_UTC_DTTM,
    i.ADD_LOCAL_DTTM,
    i.RESOLVE_UTC_DTTM,
    i.RESOLVE_LOCAL_DTTM,
    i.EXPIRATION_DATE,
    i.DOESNT_EXPIRE_YN,
    i.REVIEW_DATE,
    i.ONSET_DATE,
    zrt.NAME AS INFECTION_RECORD_TYPE,
    zi.NAME AS INFECTION_TYPE,
    zs.NAME AS INF_STATUS,
    ce_add.NAME AS INFECTION_ADD_USER,
    ce_res.NAME AS INFECTION_RESOLVE_USER,
    zst.NAME AS SPECIMEN_TYPE,
    zss.NAME AS SPECIMEN_TYPE_SOURCE,
    i.COMMENT_UTC_DTTM,
    ce_cmt.NAME AS COMMENT_USER_NAME,
    i.COMMENTS
FROM i
LEFT JOIN PAT_ENC pe ON i.PAT_ENC_CSN_ID = pe.PAT_ENC_CSN_ID
INNER JOIN PATIENT p ON i.PAT_ID = p.PAT_ID
LEFT JOIN ZC_INFECTION_RECORD_TYPE zrt ON i.INFECTION_RECORD_TYPE_C = zrt.INFECTION_RECORD_TYPE_C
LEFT JOIN ZC_INFECTION zi ON i.INFECTION_TYPE_C = zi.INFECTION_C
LEFT JOIN ZC_INF_STATUS zs ON i.INF_STATUS_C = zs.INF_STATUS_C
LEFT JOIN CLARITY_EMP ce_add ON i.ADD_USER_ID = ce_add.USER_ID
LEFT JOIN CLARITY_EMP ce_res ON i.RESOLVE_USER_ID = ce_res.USER_ID
LEFT JOIN CLARITY_EMP ce_cmt ON i.COMMENT_USER_ID = ce_cmt.USER_ID
LEFT JOIN ZC_SPECIMEN_TYPE zst ON i.SPECIMEN_TYPE_C = zst.SPECIMEN_TYPE_C
LEFT JOIN ZC_SPECIMEN_SOURCE zss ON i.SPECIMEN_SOURCE_C = zss.SPECIMEN_SOURCE_C;
