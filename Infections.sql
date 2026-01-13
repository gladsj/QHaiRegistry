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
WITH BASE AS
(
    SELECT
        INFECTIONS.INFECTION_ID,
        PATIENT.PAT_ID,
        PATIENT.PAT_MRN_ID AS MRN,
        PAT_ENC.CONTACT_DATE,
        INFECTIONS.PAT_ENC_CSN_ID,
        INFECTIONS.ADD_UTC_DTTM,
        INFECTIONS.ADD_LOCAL_DTTM,
        INFECTIONS.RESOLVE_UTC_DTTM,
        INFECTIONS.RESOLVE_LOCAL_DTTM,
        INFECTIONS.EXPIRATION_DATE,
        INFECTIONS.DOESNT_EXPIRE_YN,
        INFECTIONS.REVIEW_DATE,
        INFECTIONS.ONSET_DATE,
        ZC_INFECTION_RECORD_TYPE.NAME AS INFECTION_RECORD_TYPE,
        ZC_INFECTION.NAME AS INFECTION_TYPE,
        ZC_INF_STATUS.NAME AS INF_STATUS,
        CLARITY_EMP.NAME AS INFECTION_ADD_USER,
        CLARITY_EMP2.NAME AS INFECTION_RESOLVE_USER,
        ZC_SPECIMEN_TYPE.NAME AS SPECIMEN_TYPE,
        ZC_SPECIMEN_SOURCE.NAME AS SPECIMEN_TYPE_SOURCE,
        --INFECTIONS.COMMENT_UTC_DTTM,
        --CLARITY_EMP3.NAME AS COMMENT_USER_NAME,
        INFECTIONS.COMMENTS
    FROM INFECTIONS
    LEFT JOIN PAT_ENC ON INFECTIONS.PAT_ENC_CSN_ID = PAT_ENC.PAT_ENC_CSN_ID
    INNER JOIN PATIENT ON INFECTIONS.PAT_ID = PATIENT.PAT_ID
    LEFT JOIN ZC_INFECTION_RECORD_TYPE ON INFECTIONS.INFECTION_RECORD_TYPE_C = ZC_INFECTION_RECORD_TYPE.INFECTION_RECORD_TYPE_C
    LEFT JOIN ZC_INFECTION ON INFECTIONS.INFECTION_TYPE_C = ZC_INFECTION.INFECTION_C
    LEFT JOIN ZC_INF_STATUS ON INFECTIONS.INF_STATUS_C = ZC_INF_STATUS.INF_STATUS_C
    LEFT JOIN CLARITY_EMP ON INFECTIONS.ADD_USER_ID = CLARITY_EMP.USER_ID
    LEFT JOIN CLARITY_EMP CLARITY_EMP2 ON CLARITY_EMP2.USER_ID = INFECTIONS.RESOLVE_USER_ID
    --LEFT JOIN CLARITY_EMP CLARITY_EMP3 ON CLARITY_EMP3.USER_ID = INFECTIONS.COMMENT_USER_ID
    LEFT JOIN ZC_SPECIMEN_TYPE ON INFECTIONS.SPECIMEN_TYPE_C = ZC_SPECIMEN_TYPE.SPECIMEN_TYPE_C
    LEFT JOIN ZC_SPECIMEN_SOURCE ON INFECTIONS.SPECIMEN_SOURCE_C = ZC_SPECIMEN_SOURCE.SPECIMEN_SOURCE_C
    WHERE INFECTIONS.ADD_LOCAL_DTTM BETWEEN TRUNC(SYSDATE) - 365 AND TRUNC(SYSDATE)  -- SARGable, exact same semantics
)
SELECT * FROM BASE;