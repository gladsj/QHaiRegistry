/*
*   *********************************************************************************************************************
*  	TITLE:              Patient Dialysis
*  	AUTHOR:             
*   PROJECT:            STSTVT- Quality Registry
*  	DESCRIPTION:        Get Patient Dialysis Details 
*	  DATABASE:			      Clarity
*  	VERSION CONTROL:
*   -----------------        ----------------------------------          ------------------------------------------------
		DATE             			Modified By                          		Changes
	-----------------        ----------------------------------          ------------------------------------------------
*
*   *********************************************************************************************************************
*   Restricting  Elements:
	-----------------        ----------------------------------          ------------------------------------------------
		Table Name				Column Name										DESCRIPTION
	-----------------        ----------------------------------          ------------------------------------------------
*		Patient				    PAT_MRN_ID									Filtering based on patient mrn
*		EPISODE                 START_DATE					                Filtering based on episode date range
*   *********************************************************************************************************************
*	Table Used:
	---------------------------------------------------------------------------------------------------------------------
*   View - V_PAT_DIALYSIS_HISTORY 
*   *********************************************************************************************************************
*/

SELECT /*+ LEADING(A) PUSH_PRED(A) */
       A.PAT_ID,
       L.LOC_NAME,
       P.POS_NAME,
       D.DEPARTMENT_NAME,
       DT.NAME AS DIALYSIS_TYPE,
       A.DIALYSIS_START_DATE,
       A.DIALYSIS_END_DATE,
       A.EPISODE_ID,
       A.HX_CSN_ID,
       A.HX_LINE
FROM   V_PAT_DIALYSIS_HISTORY A
       LEFT JOIN CLARITY_LOC        L  ON A.DIALYSIS_CENTER_ID     = L.LOC_ID
       LEFT JOIN CLARITY_POS        P  ON A.DIALYSIS_CENTER_ID     = P.POS_ID   -- verify model; preserved as-is
       LEFT JOIN CLARITY_DEP        D  ON A.DIALYSIS_DEPARTMENT_ID = D.DEPARTMENT_ID
       LEFT JOIN ZC_DIALYSIS_TYPE   DT ON A.DIALYSIS_TYPE_C        = DT.DIALYSIS_TYPE_C
WHERE  A.DIALYSIS_START_DATE > ADD_MONTHS(TRUNC(SYSDATE, 'MM'), -24);  -- same as TRUNC(ADD_MONTHS(SYSDATE,-24),'MM')
