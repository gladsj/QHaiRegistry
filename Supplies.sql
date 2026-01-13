/*
*   *********************************************************************************************************************
*  	TITLE:              Supplies
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
  SELECT
    PAT.PAT_ID,
    PAT.PAT_MRN_ID,
    ORC.SURGERY_DATE,
    ORC.OR_CASE_ID,
    ORL.LOG_ID,
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
SUP AS (
  SELECT
    M.SERV_AREA_NAME AS "SERVICEAREA",
    M.LOC_NAME AS "LOCATION",
    M.OR_LINK_CSN AS "ENCOUNTERID",
    M.SURGERY_DATE,
    M.PAT_MRN_ID AS "MRN",
    M.OR_CASE_ID AS "CASEID",
    M.LOG_ID AS "LOGID",
    NULL AS IMPLANT_ID,
    'SUPPLY' AS "ITEMCLASS",
    PCKSUP.SUPPLY_ID AS "ITEMID",
    SUP.SUPPLY_NAME AS "ITEMNAME",
    ITEMTYPE.NAME AS "ITEMTYPE",
    ZPT.NAME AS "PERIOPERATIVELOCATION",
    PRO.OR_PROC_ID AS "PROCEDURECODE",
    OPR.PROC_NAME AS "PROCEDURE",
    ZMFC.NAME AS "MANUFACTURER",
    MFC.MAN_CTLG_NUM AS "MANUFACTURER#",
    '' AS "LOTNUMBER",
    '' AS "SERIAL#",
    '' AS "MODELNUMBER",
    '' AS "IMPLANTAREA",
    '' AS "IMPLANTEDDATE",
    '' AS "EXPLANTEDDATE",
    '' AS "WASTED_DATE",
    NULL AS "EXPIRATIONDATE",
    PCKSUP.NUM_NEEDED_OPEN AS "QUANTITYOPEN",
    PCKSUP.NUM_SUPPLIES_PRN AS "QUANTITYPRN",
    PCKSUP.NUM_NEEDED_OPEN AS "QUANTITY",
    PCKSUP.SUPPLIES_USED AS "QUANTITYUSED",
    PCKSUP.SUPPLIES_WASTED AS "QUANTITYWASTED",
    RSNWASTED.NAME AS "REASONWASTED",
    PCKSUP.RSN_SUP_WASTED_C AS "REASONWASTEDCODE",
    NVL(PCKSUP.SUP_UNIT_COST, 0) AS "COSTPERUNIT",
    PCKSUP.CHARGEABLE_YN AS "CHARGEABLE?",
    NVL(PCKSUP.SUP_UNIT_CHARGE, 0) AS "CHARGEPERUNIT",
    NVL(PCKSUP.SUP_UNIT_WASTE_CHRG, 0) AS "WASTEDCHARGEPERUNIT",
    INVLOC.LOC_NAME AS "INVENTORYLOCATION",
    '' AS "PRODUCT_STATUS",
    '' AS "SERVICE"
  FROM MAIN M
  LEFT JOIN OR_PKLST PCK
    ON PCK.LOG_ID = M.LOG_ID
  LEFT JOIN OR_CASE_ALL_PROC PRO
    ON M.OR_CASE_ID = PRO.OR_CASE_ID
  LEFT JOIN OR_PROC OPR
    ON OPR.OR_PROC_ID = PRO.OR_PROC_ID
  LEFT JOIN OR_PKLST_SUP_LIST PCKSUP
    ON PCKSUP.PICK_LIST_ID = PCK.PICK_LIST_ID
   AND (PCKSUP.IMPLANT_YN IS NULL OR PCKSUP.IMPLANT_YN = 'N')
  LEFT JOIN OR_SPLY SUP
    ON PCKSUP.SUPPLY_ID = SUP.SUPPLY_ID
  LEFT JOIN ZC_OR_TYPE_OF_ITEM ITEMTYPE
    ON SUP.TYPE_OF_ITEM_C = ITEMTYPE.TYPE_OF_ITEM_C
  LEFT JOIN ZC_OR_RSN_WASTED RSNWASTED
    ON PCKSUP.RSN_SUP_WASTED_C = RSNWASTED.RSN_SUP_WASTED_C
  LEFT JOIN CLARITY_LOC INVLOC
    ON PCKSUP.SUPPLY_INV_LOC_ID = INVLOC.LOC_ID
  LEFT JOIN OR_SPLY_MANFACTR MFC
    ON SUP.SUPPLY_ID = MFC.ITEM_ID
   AND MFC.LINE = 1
  LEFT JOIN ZC_OR_MANUFACTURER ZMFC
    ON MFC.MANUFACTURER_C = ZMFC.MANUFACTURER_C
  LEFT JOIN ZC_PICKLIST_TYPE ZPT
    ON ZPT.PICKLIST_TYPE_C = PCK.PICK_LIST_TYPE_C
)
SELECT * FROM SUP;