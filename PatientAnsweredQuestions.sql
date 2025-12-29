/*
**********************************************************************************************************************
*    TITLE:              Patient Encounter Question and Answers
*    AUTHOR:              
*    PROJECT:            STSTVT- Quality Registry
*    DESCRIPTION:        Get Patient answered questions details(Get Assessment details - KCCQ12) 
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
PAT_ENC_QUESR, CL_QQUEST, PATIENT, PATIENT_3
**********************************************************************************************************************
*/ 

SELECT
 
  pe.PAT_ID,
  p.PAT_MRN_ID AS MRN,
  pe.PAT_ENC_CSN_ID AS ENCOUNTERID,
  pe.LINE,
  pe.CONTACT_DATE,
  pe.QUESR_ID,
  pe.QUESR_DATE,
  pe.QUESR_UNIQUE_ID,
  pe.QUEST_ID,
  pe.QUEST_DATE,
  pe.QUEST_ANSWER,
  pe.QUEST_COMMENT,
  pe.QUEST_LINE_NUM,
  q.QUEST_NAME
FROM dbo.PAT_ENC_QUESR pe
INNER JOIN dbo.PATIENT p
  ON p.PAT_ID = pe.PAT_ID
INNER JOIN dbo.PATIENT_3 vp
  ON vp.PAT_ID = p.PAT_ID
  AND vp.IS_TEST_PAT_YN = 'N'
LEFT JOIN dbo.CL_QQUEST q
  ON q.QUEST_ID = pe.QUEST_ID
WHERE
  pe.CONTACT_DATE >= TRUNC(ADD_MONTHS(SYSDATE, -12), 'MM')  -- start of month 12 months ago
  AND pe.CONTACT_DATE <= TRUNC(SYSDATE, 'MM');              -- start of current month (inclusive)
