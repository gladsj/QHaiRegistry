/*
*   *********************************************************************************************************************
*  	TITLE:              EpisodeOfCare
*  	AUTHOR:             
*   PROJECT:            STSTVT- Quality Registry
*  	DESCRIPTION:        Data Elements which are used in creating EpisodeOfCare Resource from Epic EMR.
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
*	EpisodeOfCare:PAT_ENC, CLARITY_SER, EPI_PROBLEM_LIST, PROBLEM_LIST, EPISODE, EPISODE_LINK,
*                   EPISODE_HISTORY, EPISODE_DEF
*   *********************************************************************************************************************
*/


-- Note: Preserves the same filtering logic (monthly window, joins, DISTINCT) and output.
-- Uses early filtering, parameter reuse, and pre-dedup of EPISODE_LINK to reduce row explosion.
WITH params AS (
  SELECT
    TRUNC(ADD_MONTHS(SYSDATE, -12), 'MM') AS period_start, -- One year start
    TRUNC(SYSDATE, 'MM')                   AS period_end,   -- start of current month
  FROM DUAL
),
EPISODE_HISTORY_CTE AS (
  SELECT
      EH.SUMMARY_BLOCK_ID,
      LISTAGG(ZS.NAME, '{{delimiter}}') WITHIN GROUP (ORDER BY EH.HISTORY_START_DT) AS HISTORY_STATUS_C,
      LISTAGG(
        TO_CHAR(
          (FROM_TZ(CAST(EH.HISTORY_START_DT AS TIMESTAMP), 'America/New_York') AT TIME ZONE 'UTC'),
          'YYYY-MM-DD"T"HH24:MI:SS"Z"'
        ),
        '{{delimiter}}'
      ) WITHIN GROUP (ORDER BY EH.HISTORY_START_DT) AS HISTORY_START_DT,
      LISTAGG(
        TO_CHAR(
          (FROM_TZ(CAST(EH.HISTORY_END_DT AS TIMESTAMP), 'America/New_York') AT TIME ZONE 'UTC'),
          'YYYY-MM-DD"T"HH24:MI:SS"Z"'
        ),
        '{{delimiter}}'
      ) WITHIN GROUP (ORDER BY EH.HISTORY_START_DT) AS HISTORY_END_DT
  FROM EPISODE_HISTORY EH
  LEFT JOIN ZC_EPI_STATUS ZS
    ON ZS.EPI_STATUS_C = EH.HISTORY_STATUS_C
  CROSS JOIN params p
  WHERE EH.HISTORY_START_DT >= p.period_start
    AND EH.HISTORY_END_DT   <  p.period_end
  GROUP BY EH.SUMMARY_BLOCK_ID
),
DIAGNOSIS_CTE AS (
  SELECT
      PED.PAT_ENC_CSN_ID,
      LISTAGG(PED.PRIMARY_DX_YN, '{{delimiter}}') WITHIN GROUP (ORDER BY PED.LINE) AS PRIMARY_DX_YN,
      LISTAGG(TO_CHAR(PED.PAT_ENC_CSN_ID) || TO_CHAR(PED.LINE) || NVL(TO_CHAR(PED.PRIMARY_DX_YN), ''), '{{delimiter}}')
        WITHIN GROUP (ORDER BY PED.LINE) AS DX_ID,
      LISTAGG(CE.DX_NAME, '{{delimiter}}') WITHIN GROUP (ORDER BY PED.LINE) AS DX_NAME
  FROM PAT_ENC_DX PED
  LEFT JOIN CLARITY_EDG CE
    ON CE.DX_ID = PED.DX_ID
  CROSS JOIN params p
  WHERE PED.contact_date >= p.period_start
    AND PED.contact_date <  p.period_end
  GROUP BY PED.PAT_ENC_CSN_ID
),
-- Prefilter EPISODE to the monthly window up front (same predicate as original WHERE).
EP AS (
  SELECT
    E.EPISODE_ID,
    E.SUM_BLK_TYPE_ID,
    E.PRIMARY_LPL_ID,
    E.STATUS_C,
    E.START_DATE,
    E.END_DATE,
    E.COMMENTS
  FROM EPISODE E
  CROSS JOIN params p
  WHERE E.START_DATE >= p.period_start
    AND E.END_DATE   <  p.period_end
),
-- Deduplicate EPISODE_LINK to the keys used, and restrict to relevant episodes.
EL AS (
  SELECT DISTINCT
    L.EPISODE_ID,
    L.PAT_ENC_CSN_ID,
    L.LINE
  FROM EPISODE_LINK L
  INNER JOIN EP E
    ON E.EPISODE_ID = L.EPISODE_ID
)
SELECT DISTINCT
       E.EPISODE_ID || EL.LINE AS EPISODE_ID,
       ZC_STATUS.NAME,
       EPH.HISTORY_STATUS_C,
       EPH.HISTORY_START_DT,
       EPH.HISTORY_END_DT,
       E.SUM_BLK_TYPE_ID,
       EPISODE_DEF.EPISODE_TYPE_C,
       EPISODE_DEF.EPISODE_DEF_NAME,
       E.PRIMARY_LPL_ID,
       DGN.DX_ID  AS DIAGNOSISID,
       DGN.DX_NAME AS DIAGNOSISNAME,
       PATIENT.PAT_MRN_ID AS MRN,
       PAT_ENC.PAT_ENC_CSN_ID as ENCOUNTERID,
       TO_CHAR(
         (FROM_TZ(CAST(E.START_DATE AS TIMESTAMP), 'America/New_York') AT TIME ZONE 'UTC'),
         'YYYY-MM-DD"T"HH24:MI:SS"Z"'
       ) AS START_DATE,
       TO_CHAR(
         (FROM_TZ(CAST(E.END_DATE AS TIMESTAMP), 'America/New_York') AT TIME ZONE 'UTC'),
         'YYYY-MM-DD"T"HH24:MI:SS"Z"'
       ) AS END_DATE,
       COALESCE(PAT_ENC.ATTND_PROV_ID, PAT_ENC.PCP_PROV_ID) AS ATTND_PROV_ID,
       E.COMMENTS
FROM EP E
LEFT JOIN EPISODE_HISTORY_CTE EPH
    ON EPH.SUMMARY_BLOCK_ID = E.EPISODE_ID
LEFT JOIN EPISODE_DEF
    ON E.SUM_BLK_TYPE_ID = EPISODE_DEF.EPISODE_DEF_ID
INNER JOIN EL
    ON E.EPISODE_ID = EL.EPISODE_ID
INNER JOIN PAT_ENC
    ON PAT_ENC.PAT_ENC_CSN_ID = EL.PAT_ENC_CSN_ID
INNER JOIN PATIENT
    ON PAT_ENC.PAT_ID = PATIENT.PAT_ID
LEFT JOIN ZC_EPI_STATUS ZC_STATUS
    ON ZC_STATUS.EPI_STATUS_C = E.STATUS_C
LEFT JOIN DIAGNOSIS_CTE DGN
    ON DGN.PAT_ENC_CSN_ID = EL.PAT_ENC_CSN_ID
INNER JOIN PATIENT_3 VP
   ON PATIENT.PAT_ID = VP.PAT_ID
   AND VP.IS_TEST_PAT_YN = 'N'
-- Below code Added to get incremental data, THIS CODE TO BE COMMENTED FOR FULL LOAD
-- INNER JOIN EPIC_UTIL.CSA_EPISODE CSA ON E.EPISODE_ID = CSA.EPISODE_ID AND TRUNC(CSA._UPDATE_DT) = TRUNC(SYSDATE)
;
