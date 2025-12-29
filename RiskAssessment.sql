/*
**********************************************************************************************************************
*    TITLE:              RiskAssessment / Risk Factor
*    AUTHOR:              
*    PROJECT:            STSTVT- Quality Registry
*    DESCRIPTION:        Data Elements which are used in getting RiskAssessment details from EMR
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
MDS_RECS,ALERT,PROBLEM_LIST,ENC_NOTE_INFO
**********************************************************************************************************************
*/ 


WITH params AS (
  SELECT
    TRUNC(ADD_MONTHS(TRUNC(SYSDATE, 'MM'), -12)) AS period_start,
    TRUNC(SYSDATE, 'MM')                           AS period_end
  FROM dual
),
eligible_pats AS (
  /* Precompute the eligible patient set once (same logic as the original EXISTS).
     DISTINCT preserves the original semi-join semantics. */
  SELECT /*+ MATERIALIZE */
         DISTINCT pe.pat_id
  FROM pat_enc pe
  JOIN patient_4 p4
    ON p4.pat_id = pe.pat_id
  LEFT JOIN patient_type pt
    ON pt.pat_id = p4.pat_id
  CROSS JOIN params prms
  WHERE pe.contact_date >= prms.period_start
    AND pe.contact_date <= prms.period_end
    /* Equivalent to COALESCE(pt.patient_type_c,'0') <> '8', but sargable */
    AND (pt.patient_type_c IS NULL OR pt.patient_type_c <> '8')
)
SELECT
  m.REGISTRY_DATA_ID,
  m.REGISTRY_TYPE_C,
  m.PPS_TYPE_C,
  m.CUR_STAT_C,
  m.ENTRY_DISCHRG_C,
  m.MDS_ASSESS_INDIC_C_NAME,
  m.PAT_ID AS MRN,
  a.BPA_LOCATOR_ID,
  a.ALERT_DESC,
  p.DESCRIPTION,
  a.PAT_CSN AS ENCOUNTERID,
  e.ENCOUNTER_NOTE_ID
FROM MDS_RECS m
/* Replace correlated EXISTS with a semi-join to the precomputed eligible set */
JOIN eligible_pats ep
  ON ep.pat_id = m.pat_id
/* Remove LATERAL and 1=1; direct left join preserves row-multiplication semantics */
LEFT JOIN ALERT a
  ON a.PAT_ID = m.PAT_ID
LEFT JOIN ENC_NOTE_INFO e
  ON e.PAT_ENC_CSN_ID = a.PAT_CSN
LEFT JOIN PROBLEM_LIST p
  ON p.PAT_ID = m.PAT_ID
/* Keep the CROSS JOIN to params to strictly preserve original shape (single-row CTE) */
CROSS JOIN params prms;
