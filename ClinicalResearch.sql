
/*
*   *********************************************************************************************************************
*    TITLE:              Clinical Research
*    AUTHOR:              
*    DESCRIPTION:        Get Clinical Research Record details
* 
* 
*  DATABASE:  Clarity (Epic)
*  VERSION CONTROL: 
*   -----------------     ----------------------------------          ------------------------------------------------
DATE                       Modified By                                 Changes
-----------------          ----------------------------------          ------------------------------------------------
*********************************************************************************************************************
*   Restricting  Elements:
-----------------        ----------------------------------          ------------------------------------------------
Table Name              Column Name                                    DESCRIPTION

-----------------        ----------------------------------          ------------------------------------------------
*   *********************************************************************************************************************
*  Table Used:
---------------------------------------------------------------------------------------------------------------------
ENROLL_INFO,ZC_ENROLL_STATUS,CLARITY_RSH
*   *********************************************************************************************************************
*/

/* Same filtering logic: prior-month half-open interval [start_of_prior_month, start_of_current_month) */
SELECT
  EI.ENROLL_ID,
  EI.RECORD_STATUS_C,
  EI.ENROLL_STATUS_C,
  ZES.NAME AS ENROLL_STATUS,               -- keep both aliases for NAME per original
  CR.RECORD_STATUS_C,
  ZES.NAME AS ENROLLMENTSTATUS,
  EI.RESEARCH_STUDY_ID,
  CR.RESEARCH_NAME,
  EI.PAT_ID,
  EI.STUDY_ALIAS,
  EI.ENROLL_START_DT,
  EI.ENROLL_END_DT,
  EI.ENROLL_CMT_NOTE_ID,
  EI.LAST_MOD_DTTM,
  EI.STUDY_BRANCH_ID,
  EI.FIRST_INVITATION_SENT_YN,
  ZLMS.NAME AS FIRST_INVITE_LAST_MOD_SOURCE_NAME,
  EI.FIRST_INVITATION_SENT_UTC_DTTM
FROM (
  /* Predicate pushed before joins; same semantics */
  SELECT /*+ NO_MERGE */ *
  FROM ENROLL_INFO
  WHERE ENROLL_START_DT >= ADD_MONTHS(TRUNC(SYSDATE, 'MM'), -12) -- One Year data
    AND ENROLL_END_DT   <  TRUNC(SYSDATE, 'MM')
) EI
LEFT JOIN CLARITY_RSH       CR   ON CR.RECORD_STATUS_C = EI.RECORD_STATUS_C
LEFT JOIN ZC_LAST_MOD_SOURCE ZLMS ON EI.FIRST_INVITE_LAST_MOD_SOURCE_C = ZLMS.LAST_MOD_SOURCE_C
LEFT JOIN ZC_ENROLL_STATUS   ZES  ON ZES.ENROLL_STATUS_C = EI.ENROLL_STATUS_C;
