/*
*   *********************************************************************************************************************
*  	TITLE:              Patient Allergy
*  	AUTHOR:             
*   PROJECT:            STSTVT Registry
*  	DESCRIPTION:        Data Elements which are used for getting patient allergy details.
*	  DATABASE:			      Clarity
*  	VERSION CONTROL:
*   -----------------        ----------------------------------          ------------------------------------------------
		DATE             			Modified By                          		Changes
	-----------------        ----------------------------------          ------------------------------------------------
	
*   *********************************************************************************************************************
*   Restricting  Elements:
	-----------------        ----------------------------------          ------------------------------------------------
		Table Name				Column Name										DESCRIPTION
	-----------------        ----------------------------------          ------------------------------------------------
*		Patient					 PAT_MRN_ID									Filtering based on patient mrn
*       ALLERGY                  ALRGY_ENTERED_DTTM                         Filtering based on daterange of allergy entered
*   *********************************************************************************************************************
*	Table Used:
	---------------------------------------------------------------------------------------------------------------------
	Allergies: ALLERGY, ZC_SEVERITY, CL_ELG, ZC_ALLERGEN_TYPE, ZC_ALLERGY_SEVERIT, PATIENT,ALLERGY_REACTIONS,ZC_REACTION
*   *********************************************************************************************************************
*/

WITH VP AS (
  SELECT /*+ MATERIALIZE */
         DISTINCT PAT_ID
  FROM PATIENT_3
  WHERE IS_TEST_PAT_YN = 'N'
)
SELECT
    A.ALLERGY_ID,
    S.NAME AS ALLERGYSTATUSNAME,
    S.ALRGY_STATUS_C AS ALLERGYSTATUS,
    S.NAME AS STATUSNAME,
    SV.NAME AS SEVERITYNAME,
    SEV.NAME AS ALLERGYSEVERITNAME,
    ATYP.NAME AS ALLERGENTYPE,
    E.ALLERGEN_ID,
    E.ALLERGEN_NAME,
    P.PAT_MRN_ID,
    TRUNC(A.DATE_NOTED) AS ONSETDATE,
    TRUNC(A.DATE_NOTED) AS recordedDate,
    CE.PROV_ID,
    A.REACTION,
    R.Reactions,
    -- Convert/normalize entered datetime to UTC and format as ISO-like string.
    TO_CHAR(
      (FROM_TZ(CAST(A.ALRGY_ENTERED_DTTM AS TIMESTAMP), 'US/Eastern') AT TIME ZONE 'UTC'),
      'YYYY-MM-DD"T"HH24:MI:SS"Z"'
    ) AS ALLERGYENTEREDDATE
FROM ALLERGY A
JOIN PATIENT P
  ON P.PAT_ID = A.PAT_ID
JOIN VP
  ON VP.PAT_ID = P.PAT_ID
LEFT JOIN ZC_ALRGY_STATUS S
  ON A.ALRGY_STATUS_C = S.ALRGY_STATUS_C
LEFT JOIN ZC_SEVERITY SV
  ON SV.SEVERITY_C = A.SEVERITY_C
LEFT JOIN CL_ELG E
  ON E.ALLERGEN_ID = A.ALLERGEN_ID
LEFT JOIN ZC_ALLERGEN_TYPE ATYP
  ON ATYP.ALLERGEN_TYPE_C = E.ALLERGEN_TYPE_C
LEFT JOIN ZC_ALLERGY_SEVERIT SEV
  ON SEV.ALLERGY_SEVERITY_C = A.ALLERGY_SEVERITY_C
LEFT JOIN CLARITY_EMP CE
  ON CE.USER_ID = A.ENTRY_USER_ID
OUTER APPLY (
  SELECT LISTAGG(ZR.NAME, ',') WITHIN GROUP (ORDER BY AR.LINE ASC) AS Reactions
  FROM ALLERGY_REACTIONS AR
  LEFT JOIN ZC_REACTION ZR
    ON ZR.REACTION_C = AR.REACTION_C
  WHERE AR.ALLERGY_ID = A.ALLERGY_ID
) R
WHERE A.ALRGY_ENTERED_DTTM >= TRUNC(SYSDATE) - 365;
