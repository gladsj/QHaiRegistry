/*
* *********************************************************************************************************************
*    TITLE:        CarePlan Notes
*    AUTHOR:       
*    PROJECT:	     Heart Failure - HF Use Case
*    DESCRIPTION:  Get CarePlan Note details
                   
*    DATABASE:  Clarity  
*    VERSION CONTROL:  1.0 
*   -----------------        ----------------------------------          ------------------------------------------------  
        DATE                   Modified By                                  Changes 
    -----------------        ----------------------------------          ------------------------------------------------ 
*
*   *********************************************************************************************************************
*   Restricting  Elements: 
    -----------------        ----------------------------------          ------------------------------------------------  
        Table Name             Column Name                                 DESCRIPTION 
    -----------------        ----------------------------------          ------------------------------------------------ 
*       PATIENT                PAT_ID                                      filtering based on patient ID 
*   *********************************************************************************************************************
*  Table Used: 
    ---------------------------------------------------------------------------------------------------------------------
*   CAREPLAN_PROG_NOTE, HNO_INFO, HNO_NOTE_TEXT, PATIENT, ZC_NOTE_TYPE_IP
    ---------------------------------------------------------------------------------------------------------------------
*   *********************************************************************************************************************
*/

/* Push the CONTACT_DATE filter directly onto HNO_NOTE_TEXT and remove the CROSS JOIN */
SELECT
    P.PAT_ID,
    P.PAT_MRN_ID,
    CPN.CARE_INTG_ID,          -- LCP -- PROGRESS NOTES FROM CAREPLANS ACTIVITIES
    CPN.LINE,
    H.NOTE_ID,
    H.PAT_ENC_CSN_ID,
    ZT.NAME AS NOTE_TYPE,
    NT.NOTE_TEXT
FROM HNO_NOTE_TEXT NT
JOIN HNO_INFO H
  ON NT.NOTE_ID = H.NOTE_ID
JOIN CAREPLAN_PROG_NOTE CPN
  ON CPN.CP_PROG_NOTES_ID = H.NOTE_ID
JOIN PATIENT P
  ON H.PAT_ID = P.PAT_ID
JOIN ZC_NOTE_TYPE_IP ZT
  ON H.IP_NOTE_TYPE_C = ZT.TYPE_IP_C
 AND ZT.ZC_NOTE_TYPE_IP_C = '1000001'  -- CarePlan NoteType
WHERE
  /* Semantics preserved: >= TRUNC(SYSDATE)-365 and <= TRUNC(SYSDATE) (inclusive) */
  NT.CONTACT_DATE BETWEEN TRUNC(SYSDATE) - 365 AND TRUNC(SYSDATE);
