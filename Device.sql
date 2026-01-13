/*
*   *********************************************************************************************************************
*  	TITLE:              Device 
*  	AUTHOR:             
*   Project:            STSTVT- Quality Registry  
*  	DESCRIPTION:        Data Elements which are used in creating Device FHIR Resource for Clarity EMR.
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
*		DEVICE					DEVICE_ID 							       filtering based on Device internal id
*   *********************************************************************************************************************
*	Table Used:
	--------------------------------------------------------------------------------------------------------------------- 
    Device : DEVICE_INFO,PATIENT,DEVICE_TYPE_INFO,DEVICE_LOC_INFO,IP_DATA_STORE,ZC_DEL_STATUS,ZC_SPECIAL_TYPE_2
*   *********************************************************************************************************************
*/

/* ENC was effectively an INNER JOIN due to the WHERE filter on ENC.CONTACT_DATE.
   We pre-filter PAT_ENC in a CTE (enc_filt) and join it INNER to expose true join cardinality
   and enable index range scans on CONTACT_DATE. Semantics preserved exactly. */
WITH enc_filtered AS (
  SELECT
    pat_id,
    inpatient_data_id,
    pat_enc_csn_id,
    contact_date
  FROM pat_enc
  WHERE contact_date >= ADD_MONTHS(TRUNC(SYSDATE, 'MM'), -1)
                         AND TRUNC(SYSDATE, 'MM')
),
flw_dedup AS (
  SELECT DISTINCT
    inpatient_data_id,
    device_id
  FROM ip_device_capture
)
SELECT
  ENC.PAT_ID,
  PAT.PAT_MRN_ID AS MRN,
  PAT.PAT_NAME,
  ENC.CONTACT_DATE,
  FLW.INPATIENT_DATA_ID,
  ENC.PAT_ENC_CSN_ID,
  DI.DEVICE_ID AS DEVICEID,
  ZDS.NAME AS DEVICESTATUS,
  DI.DEVICE_NAME AS DEVICENAME,
  DI.DEVICE_NAME AS DESCRIPTION,
  DI.DEVICE_TYPE_ID AS DEVICETYPEID,
  DI.DEVICE_TYPE_ID AS DEVICETYPECODE,
  DTI.DEVICE_TYPE_NAME AS DEVICETYPENAME,
  DTI.DEVICE_TYPE_NAME AS DEVICETYPE,
  DTI.SPECIAL_TYPE_C AS DEVICESPECLIZATIONTYPECODE,
  ZST2.NAME AS DEVICESPECLIZATIONTYPE,
  DI.HOSPITAL_ID AS LOCATIONID,
  DI.DEVICE_IP AS DEVICEIP,
  DI.DEVICE_DESC AS DEVICEDESCRPTION
FROM enc_filtered ENC
JOIN flw_dedup FLW
  ON FLW.INPATIENT_DATA_ID = ENC.INPATIENT_DATA_ID
JOIN device_info DI
  ON DI.DEVICE_ID = FLW.DEVICE_ID
LEFT JOIN patient PAT
  ON ENC.PAT_ID = PAT.PAT_ID
LEFT JOIN zc_del_status ZDS
  ON ZDS.DEL_STATUS_C = DI.RECORD_STATE_C
LEFT JOIN device_type_info DTI
  ON DTI.DEVICE_TYPE_ID = DI.DEVICE_TYPE_ID
LEFT JOIN zc_special_type_2 ZST2
  ON ZST2.SPECIAL_TYPE_2_C = DTI.SPECIAL_TYPE_C
WHERE EXISTS (
  SELECT 1
  FROM ip_data_store IDS
  WHERE IDS.INPATIENT_DATA_ID = FLW.INPATIENT_DATA_ID
);