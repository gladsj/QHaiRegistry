/*
*   *********************************************************************************************************************
*  	TITLE:              Implants
*  	AUTHOR:
*   PROJECT:            STSTVT- Quality Registry
*  	DESCRIPTION:        Get details on the Implants for the Patient
*	  DATABASE:	          Clarity
*  	VERSION CONTROL:
*   -----------------        ----------------------------------          ------------------------------------------------
		DATE             			    Modified By                          	       	    Changes
	-----------------        ----------------------------------          ------------------------------------------------
*
*
*   *********************************************************************************************************************
*   Restricting  Elements:
	-----------------        ----------------------------------          ------------------------------------------------
		Table Name				    Column Name									    DESCRIPTION
	-----------------        ----------------------------------          ------------------------------------------------
*       OR_IMP				        IMPLANT_ID 							    filtering based on Implant internal id
*   *********************************************************************************************************************
*	Table Used:
	---------------------------------------------------------------------------------------------------------------------

*   *********************************************************************************************************************
*/
WITH MAIN AS (
  SELECT /*+ MATERIALIZE */
    PAT.PAT_ID,
    PAT.PAT_MRN_ID,
    ORC.SURGERY_DATE,
    ORC.OR_CASE_ID,
    ORC.LOG_ID,
    SA.SERV_AREA_NAME,
    LOC.LOC_NAME,
    PATL.OR_LINK_CSN
  FROM OR_CASE ORC
  INNER JOIN OR_LOG ORL
    ON ORL.LOG_ID = ORC.LOG_ID
   AND ORL.LOG_TYPE_C = 0
  LEFT JOIN PAT_OR_ADM_LINK PATL
    ON PATL.CASE_ID = ORC.OR_CASE_ID
  LEFT JOIN PATIENT PAT
    ON ORC.PAT_ID = PAT.PAT_ID
  LEFT JOIN CLARITY_LOC LOC
    ON LOC.LOC_ID = ORC.LOC_ID
  LEFT JOIN CLARITY_SA SA
    ON LOC.SERV_AREA_ID = SA.SERV_AREA_ID
  WHERE ORC.SURGERY_DATE BETWEEN TRUNC(SYSDATE) - 365 AND TRUNC(SYSDATE)
),
IMP AS (
  SELECT
    M.SERV_AREA_NAME AS "SERVICEAREA",
    M.LOC_NAME AS "LOCATION",
    M.OR_LINK_CSN AS "ENCOUNTERID",
    M.SURGERY_DATE,
    M.PAT_MRN_ID AS "MRN",
    M.OR_CASE_ID AS "CASEID",
    M.LOG_ID AS "LOGID",
    LNLG.IMPLANT_ID,
    'IMPLANT' AS "ITEMCLASS",
    LNLG.IMPLANT_ID AS "ITEMID",
    IMP.IMPLANT_NAME AS "ITEMNAME",
    IMPTYPE.NAME AS "ITEMTYPE",
    ZPT.NAME AS "PERIOPERATIVELOCATION",
    TO_CHAR(CHG.PROCEDURE_CODE_ID) AS "PROCEDURECODE",
    EAP.PROC_NAME AS "PROCEDURE",
    ZMFC.NAME AS "MANUFACTURER",
    IMP.MANUF_NUM AS "MANUFACTURER#",
    IMP.LOT_NUMBER AS "LOTNUMBER",
    IMP.SERIAL_NUMBER AS "SERIAL#",
    IMP.MODEL_NUMBER AS "MODELNUMBER",
    ZAREA.NAME AS "IMPLANTAREA",
    OR_IMP_IMPLANT.IMPLANTED_DATE AS "IMPLANTEDDATE",
    OR_IMP_EXPLANT.EXPLANTED_DATE AS "EXPLANTEDDATE",
    OR_IMP_WASTED.WASTED_DATE,
    IMP.EXPIRATION_DATE AS "EXPIRATIONDATE",
    NULL AS "QUANTITYOPEN",
    NULL AS "QUANTITYPRN",
    CHG.QUANTITY AS "QUANTITY",
    CASE
      WHEN LNLG.IMPLANT_USAGE_C IS NULL OR LNLG.IMPLANT_USAGE_C = 1 THEN LNLG.IMPLANT_NUM_USED
      ELSE 0
    END AS "QUANTITYUSED",
    CASE
      WHEN LNLG.IMPLANT_USAGE_C = 2 THEN LNLG.IMPLANT_NUM_USED
      ELSE 0
    END AS "QUANTITYWASTED",
    WASTE.NAME AS "REASONWASTED",
    LNLG.IMPLANT_RSN_WSTD_C AS "REASONWASTEDCODE",
    NVL(IMP.COST_PER_UNIT, 0) AS "COSTPERUNIT",
    IMP.CHARGEABLE_YN AS "CHARGEABLE?",
    CASE
      WHEN (LNLG.IMPLANT_ACTION_C <> 3 AND LNLG.IMPLANT_UNIT_CHARGE IS NOT NULL)
      THEN LNLG.IMPLANT_UNIT_CHARGE
      ELSE 0
    END AS "CHARGEPERUNIT",
    CASE
      WHEN (LNLG.IMPLANT_ACTION_C = 3 AND LNLG.IMPLANT_UNIT_CHARGE IS NOT NULL)
      THEN LNLG.IMPLANT_UNIT_CHARGE
      ELSE 0
    END AS "WASTEDCHARGEPERUNIT",
    INVLOC.LOC_NAME AS "INVENTORYLOCATION",
    ZC_OR_IMP_STATUS.NAME AS "PRODUCT_STATUS"
  FROM MAIN M
  INNER JOIN OR_LOG_LN_IMPLANT ORLN
    ON M.LOG_ID = ORLN.LOG_ID
  LEFT OUTER JOIN OR_LNLG_IMPLANTS LNLG
    ON ORLN.IMPLANTS_ID = LNLG.RECORD_ID
  LEFT OUTER JOIN OR_IMP IMP
    ON LNLG.IMPLANT_ID = IMP.IMPLANT_ID
  /* keep original semantics for these joins; only replaced OR_CASE.LOG_ID with M.LOG_ID */
  LEFT OUTER JOIN OR_IMP_IMPLANT
    ON OR_IMP_IMPLANT.IMPLANT_LOG_ID = M.LOG_ID
  LEFT OUTER JOIN OR_IMP_EXPLANT
    ON OR_IMP_IMPLANT.IMPLANT_ID = OR_IMP_EXPLANT.IMPLANT_ID
  LEFT OUTER JOIN OR_IMP_WASTED
    ON IMP.IMPLANT_ID = OR_IMP_WASTED.IMPLANT_ID
  LEFT OUTER JOIN ZC_OR_IMP_STATUS
    ON ZC_OR_IMP_STATUS.STATUS_C = IMP.STATUS_C
  LEFT OUTER JOIN OR_LOG_CHARGES CHG
    ON CHG.LOG_ID = M.LOG_ID
   AND IMP.IMPLANT_ID = CHG.CHARGE_IMPLANT_ID
  LEFT OUTER JOIN ZC_IMPLANT_AREA ZAREA
    ON ZAREA.IMPLANT_AREA_C = IMP.IMPLANT_AREA_C
  LEFT OUTER JOIN CLARITY_LOC INVLOC
    ON IMP.SITE_ID = INVLOC.LOC_ID
  LEFT OUTER JOIN ZC_OR_IMPLANT_TYPE IMPTYPE
    ON IMP.IMPLANT_TYPE_C = IMPTYPE.IMPLANT_TYPE_C
  LEFT OUTER JOIN ZC_OR_RSN_WASTE WASTE
    ON LNLG.IMPLANT_RSN_WSTD_C = WASTE.REASON_WASTED_C
  LEFT OUTER JOIN ZC_OR_MANUFACTURER ZMFC
    ON ZMFC.MANUFACTURER_C = IMP.MANUFACTURER_C
  LEFT OUTER JOIN CLARITY_EAP EAP
    ON EAP.PROC_ID = CHG.PROCEDURE_CODE_ID
  LEFT OUTER JOIN ZC_PICKLIST_TYPE ZPT
    ON ZPT.PICKLIST_TYPE_C = CHG.PICKLIST_TYPE_C
)
SELECT *
FROM IMP;