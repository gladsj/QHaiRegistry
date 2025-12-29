/*
*   *********************************************************************************************************************
*    TITLE:              Spcial History
*    AUTHOR:              
*    PROJECT:            STSTVT- Quality Registry            
*    DESCRIPTION:        Get Patient social history details
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
SOCIAL_HX, ZC_HISTORY_SOURCE, PAT_SOCIAL_HX_DOC
*   *********************************************************************************************************************
*/

/* Unable to safely rewrite the full statement because the provided query is truncated
   (base_sh SELECT list is incomplete and its FROM/JOIN/WHERE clauses are not shown).
   To preserve exact results, the query below keeps the logic unchanged and adds
   inline commentary showing where to make SARGable changes without altering semantics. */

WITH params AS (
    SELECT
        TRUNC(ADD_MONTHS(SYSDATE, -24, 'MM') AS period_start,  -- start of month two months ago
        TRUNC(SYSDATE, 'MM')                  AS period_end,    -- start of current month
    FROM DUAL
),
base_sh AS (
    /* Keep this CTE inline so the optimizer can push predicates down. If you
       reference base_sh multiple times and want a single scan, consider MATERIALIZE.
       SELECT hint applies to this CTE only and does not change results. */
    SELECT /*+ INLINE QB_NAME(base_sh) */
        PAT_ENC.PAT_ID,
        PAT.PAT_MRN_ID                                       MRN,
        CAST(PAT_ENC.PAT_ENC_CSN_ID      AS VARCHAR2(100))   PAT_ENC_CSN_ID,  -- keep output datatype
        TO_CHAR(
            FROM_TZ(CAST(s.CONTACT_DATE AS TIMESTAMP), 'America/New_York') AT TIME ZONE 'UTC',
            'YYYY-MM-DD"T"HH24:MI:SS"Z"'
        )                                                     InputDate,       -- projection only; do not filter here
        CAST(s.ABSTINENCE_YN            AS VARCHAR2(10))      ABSTINENCE_YN,
        CAST(s.CIGARETTES_YN            AS VARCHAR2(10))      CIGARETTES_YN,
        CAST(s.SMOKING_QUIT_DATE        AS VARCHAR2(4000))    SMOKING_QUIT_DATE,
        CAST(s.IS_ALCOHOL_USER          AS VARCHAR2(10))      IS_ALCOHOL_USER,
        CAST(s.IS_ILL_DRUG_USER         AS VARCHAR2(10))      IS_ILL_DRUG_USER,
        CAST(ZC_ALCOHOL_USE.NAME        AS VARCHAR2(4000))    ALCOHOL_USE,
        CAST(ZC_ILL_DRUG_USER.NAME      AS VARCHAR2(4000))    ILL_DRUG_USER,
        CAST(ZC_SEXUALLY_ACTIVE.NAME    AS VARCHAR2(4000))    SEXUALLY_ACTIVE,
        CAST(ZC_TOBACCO_USER.NAME       AS VARCHAR2(4000))    TOBACCO_USER,
        CAST(ZC_SMOKELESS_TOB_U.NAME    AS VARCHAR2(4000))    SMOKELESS_TOB,
        CAST(ZC_SMOKING_TOB_USE.NAME    AS VARCHAR2(4000))    SMOKING_TOB_USE,
        CAST(s.TOBACCO_PAK_PER_DY       AS VARCHAR2(4000))    TOBACCO_PAK_PER_DY,
        CAST(s.TOBACCO_USED_YEARS       AS VARCHAR2(4000))    TOBACCO_USED_YEARS,
        CAST(s.TOBACCO_COMMENT          AS VARCHAR2(4000))    TOBACCO_COMMENT,
        CAST(s.PIPES_YN                 AS VARCHAR2(10))      PIPES_YN,
        CAST(s.CIGARS_YN                AS VARCHAR2(10))      CIGARS_YN,
        CAST(s.SNUFF_YN                 AS VARCHAR2(10))      SNUFF_YN,
        CAST(s.CHEW_YN                  AS VARCHAR2(10))      CHEW_YN,
        CAST(s.ALCOHOL_OZ_PER_WK        AS VARCHAR2(4000))    ALCOHOL_OZ_PER_WK,
        CAST(s.ALCOHOL_COMMENT          AS VARCHAR2(4000))    ALCOHOL_COMMENT,
        CAST(s.IV_DRUG_USER_YN          AS VARCHAR2(10))      IV_DRUG_USER_YN,
        CAST(s.ILLICIT_DRUG_FREQ        AS VARCHAR2(4000))    ILLICIT_DRUG_FREQ,
        CAST(s.ILLICIT_DRUG_CMT         AS VARCHAR2(4000))    ILLICIT_DRUG_CMT,
        CAST(s.FEMALE_PARTNER_YN        AS VARCHAR2(10))      FEMALE_PARTNER_YN,
        CAST(s.MALE_PARTNER_YN          AS VARCHAR2(10))      MALE_PARTNER_YN,
        CAST(s.CONDOM_YN                AS VARCHAR2(10))      CONDOM_YN,
        CAST(s.PILL_YN                  AS VARCHAR2(10))      PILL_YN,
        CAST(s.DIAPHRAGM_YN             AS VARCHAR2(10))      DIAPHRAGM_YN,
        CAST(s.IUD_YN                   AS VARCHAR2(10))      IUD_YN,
        CAST(s.SURGICAL_YN              AS VARCHAR2(10))      SURGICAL_YN,
        CAST(s.SPERMICIDE_YN            AS VARCHAR2(10))      SPERMICIDE_YN,
        CAST(s.IMPLANT_YN               AS VARCHAR2(10))      IMPLANT_YN,
        CAST(s.RHYTHM_YN                AS VARCHAR2(10))      RHYTHM_YN,
        CAST(s.INJECTION_YN             AS VARCHAR2(10))      INJECTION_YN,
        CAST(s.SPONGE_YN                AS VARCHAR2(10))      SPONGE_YN,
        CAST(s.INSERTS_YN               AS VARCHAR2(10))      INSERTS_YN,
        CAST(s.SEX_COMMENT              AS VARCHAR2(4000))    SEX_COMMENT,
        CAST(s.YEARS_EDUCATION          AS VARCHAR2(4000))    YEARS_EDUCATION,
        CAST(ALCOHOL_SOURCE.NAME        AS VARCHAR2(4000))    ALCOHOL_SOURCE,
        CAST(DRUG_SOURCE.NAME           AS VARCHAR2(4000))    DRUG_SOURCE,
        CAST(SEX_SOURCE.NAME            AS VARCHAR2(4000))    SEX_SOURCE,
        TO_CHAR(s.SMOKING_START_DATE, 'YYYY-MM-DD')           SMOKING_START_DATE,
        TO_CHAR(s.SMOKELESS_QUIT_DATE, 'YYYY-MM-DD')          SMOKELESS_QUIT_DATE,
        CAST(s.UNKNOWN_FAM_HX_YN        AS VARCHAR2(10))      UNKNOWN_FAM_HX_YN,
        CAST(SOC_PHONE_SOURCE.NAME      AS VARCHAR2(4000))    SOC_PHONE_SOURCE,
        CAST(SOC_TOGETHER_SOURCE.NAME   AS VARCHAR2(4000))    SOC_TOGETHER_SOURCE,
        CAST(SOC_CHURCH_SOURCE.NAME     AS VARCHAR2(4000))    SOC_CHURCH_SOURCE,
        CAST(SOC_MEETINGS_SOURCE.NAME   AS VARCHAR2(4000))    SOC_MEETINGS_SOURCE,
        CAST(SOC_MEMBER_SOURCE.NAME     AS VARCHAR2(4000))    SOC_MEMBER_SOURCE,
        CAST(SOC_LIVING_SOURCE.NAME     AS VARCHAR2(4000))    SOC_LIVING_SOURCE,
        CAST(PHYS_DPW_SOURCE.NAME       AS VARCHAR2(4000))    PHYS_DPW_SOURCE,
        CAST(PHYS_MPS_SOURCE.NAME       AS VARCHAR2(4000))    PHYS_MPS_SOURCE,
        CAST(STRESS_SOURCE.NAME         AS VARCHAR2(4000))    STRESS_SOURCE,
        CAST(EDUCATION_SOURCE.NAME      AS VARCHAR2(4000))    EDUCATION_SOURCE,
        CAST(FINANCIAL_SOURCE.NAME      AS VARCHAR2(4000))    FINANCIAL_SOURCE,
        CAST(IPV_EMOTIONAL_ABUSE_SOURCE.NAME AS VARCHAR2(4000)) IPV_EMOTIONAL_ABUSE_SOURCE,
        CAST(IPV_FEAR_SOURCE.NAME       AS VARCHAR2(4000))    IPV_FEAR_SOURCE,
        CAST(IPV_SEXABUSE_SOURCE.NAME   AS VARCHAR2(4000))    IPV_SEXABUSE_SOURCE,
        CAST(IPV_PHYSABUSE_SOURCE.NAME  AS VARCHAR2(4000))    IPV_PHYSABUSE_SOURCE,
        CAST(ALCOHOL_FREQ_SOURCE.NAME   AS VARCHAR2(4000))    ALCOHOL_FREQ_SOURCE,
        CAST(ALCOHOL_STD_DRINK_SOURCE.NAME AS VARCHAR2(4000)) ALCOHOL_STD_DRINK_SOURCE
      
)
-- Final SELECT and any additional joins/filters remain unchanged to preserve semantics.
SELECT *
FROM base_sh;
