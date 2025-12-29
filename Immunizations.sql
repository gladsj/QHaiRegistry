/*
*   *********************************************************************************************************************
*  	TITLE:              Immunization
*  	AUTHOR:             
*   PROJECT:            Heart Failure HF - Use Case
*  	DESCRIPTION:        Data Elements which are used in creating  Immunization FHIR Resource from Epic EMR.
*
*
*	DATABASE:	Clarity
*  	VERSION CONTROL:
*   -----------------        ----------------------------------          ------------------------------------------------
	DATE						Modified By                          	Changes
-----------------        ----------------------------------          ------------------------------------------------
*  	2020-04-29					Vishnu Dattu K							Initial Version
*   2022-04-26			 Mahesh Ravala								 Added Code to convert dates to UTC
*	2022-05-02			 Mahesh Ravala								 Added Incremental Load Logic/code
*   *********************************************************************************************************************
*   Restricting  Elements:
-----------------        ----------------------------------          ------------------------------------------------
Table Name	Column Name	DESCRIPTION
-----------------        ----------------------------------          ------------------------------------------------
*   *********************************************************************************************************************
*	Table Used:
---------------------------------------------------------------------------------------------------------------------
IMMUNE, ZC_DEFER_REASON, CLARITY_IMMUNZATN,Patient,ZC_MFG,ZC_SITE,ZC_ROUTE
*   *********************************************************************************************************************
*/

WITH
  params AS (
    SELECT
      TRUNC(ADD_MONTHS(SYSDATE, -60), 'MM') AS period_start,
      TRUNC(SYSDATE, 'MM')                  AS period_end
    FROM dual
  ),
  /* Deduplicate and pre-filter RX_NDC once (avoid double access and duplicates) */
  ndc_f AS (
    SELECT
      r.NDC_ID,
      MAX(TRIM(r.NDC_CODE)) AS NDC_CODE
    FROM RX_NDC r
    WHERE r.NDC_CODE IS NOT NULL
    GROUP BY r.NDC_ID
  ),
  /* Deduplicate and pre-filter CLARITY_IMMUNZATN once (avoid double access and duplicates) */
  ci_f AS (
    SELECT
      c.IMMUNZATN_ID,
      MAX(TRIM(c.IMM_CVX_CODE)) AS IMM_CVX_CODE,
      MAX(c.NAME)               AS NAME
    FROM CLARITY_IMMUNZATN c
    WHERE c.IMM_CVX_CODE IS NOT NULL OR c.NAME IS NOT NULL
    GROUP BY c.IMMUNZATN_ID
  )
SELECT
    i.IMMUNE_ID                                  AS IMMUNEID,
    zis.NAME                                     AS IMMUNIZATIONSTATUS,
    zdr.NAME                                     AS DEFERREDSTATUS,
    ndc_f.NDC_CODE                               AS RX_NDC_CODE,
    ci_f.IMM_CVX_CODE                            AS IMMUNIZATIONCVXCODE,
    ci_f.NAME                                    AS IMMUNIZATIONNAME,
    p.PAT_MRN_ID                                 AS MRN,
    i.IMM_CSN                                    AS ENCOUNTERID,
    -- convert local (US/Eastern) timestamp to UTC and format ISO8601
    TO_CHAR(
      (FROM_TZ(CAST(i.IMMUNE_DATE AS TIMESTAMP), 'US/Eastern') AT TIME ZONE 'UTC'),
      'YYYY-MM-DD"T"HH24:MI:SS"Z"'
    )                                            AS IMMUNIZATIONDATE,
    TO_CHAR(
      (FROM_TZ(CAST(i.ENTRY_DATE AS TIMESTAMP), 'US/Eastern') AT TIME ZONE 'UTC'),
      'YYYY-MM-DD"T"HH24:MI:SS"Z"'
    )                                            AS IMMUNIZATIONENTRYDATE,
    i.PHYSICAL_SITE                              AS IMMMUNIZATIONSITE,
    i.MFG_C                                      AS MANUFACTURERCODE,
    zm.NAME                                      AS MANUFACTURERNAME,
    i.LOT                                        AS LOTNUMBER,
    CAST(i.EXPIRATION_DATE AS DATE)              AS EXPIRYDATE,
    zsite.NAME                                   AS SITENAME,
    zroute.NAME                                  AS ROUTE,
    i.IMMNZTN_DOSE_AMOUNT                        AS DOASAGE,
    mu.NAME                                      AS DOSAGEUNIT,
    ce.PROV_ID                                   AS DOSAGEPROVIDERID,
    ce.NAME                                      AS DOSAGEPROVIDERNAME,
    i.MED_ADMIN_COMMENT                          AS IMMUNIZATIONCOMMENT
FROM IMMUNE i
JOIN PATIENT     p   ON p.PAT_ID  = i.PAT_ID
JOIN PATIENT_3   vp  ON vp.PAT_ID = p.PAT_ID AND vp.IS_TEST_PAT_YN = 'N'
LEFT JOIN ZC_DEFER_REASON      zdr   ON zdr.DEFER_REASON_C    = i.DEFER_REASON_C
LEFT JOIN ZC_MFG               zm    ON zm.MFG_C              = i.MFG_C
LEFT JOIN ZC_SITE              zsite ON zsite.SITE_C          = i.SITE_C
LEFT JOIN ZC_ROUTE             zroute ON zroute.ROUTE_C       = i.ROUTE_C
LEFT JOIN ZC_MED_UNIT          mu    ON mu.DISP_QTYUNIT_C     = i.IMMNZTN_DOSE_UNIT_C
LEFT JOIN ZC_IMMNZTN_STATUS    zis   ON zis.IMMNZTN_STATUS_C  = i.IMMNZTN_STATUS_C
LEFT JOIN CLARITY_EMP          ce    ON ce.USER_ID            = i.GIVEN_BY_USER_ID
/* Consolidated, de-duplicated lookups (each is at most 1:1 to IMMUNE) */
LEFT JOIN ndc_f                ndc_f ON ndc_f.NDC_ID          = i.NDC_NUM_ID
LEFT JOIN ci_f                 ci_f  ON ci_f.IMMUNZATN_ID     = i.IMMUNZATN_ID
CROSS JOIN params
WHERE
    -- exact same inclusive bounds
    i.IMMUNE_DATE >= params.period_start
    AND i.IMMUNE_DATE <= params.period_end
    -- same logic as original EXISTS OR: at least one of NDC or CI is present and non-null
    AND (ndc_f.NDC_ID IS NOT NULL OR ci_f.IMMUNZATN_ID IS NOT NULL);
