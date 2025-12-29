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

WITH P3F AS (
  SELECT /*+ MATERIALIZE */
         PAT_ID
  FROM PATIENT_3
  WHERE IS_TEST_PAT_YN = 'N'
  -- Do NOT use DISTINCT here; that would change row-multiplicity vs. the original INNER JOIN
)
SELECT
    DI.DEVICE_ID                                      AS DEVICEID,
    ZDS.NAME                                          AS DEVICESTATUS,
    DI.DEVICE_NAME                                    AS DEVICENAME,
    DI.DEVICE_NAME                                    AS DESCRIPTION,
    DI.DEVICE_TYPE_ID                                 AS DEVICETYPEID,
    DI.DEVICE_TYPE_ID                                 AS DEVICETYPECODE,
    DTI.DEVICE_TYPE_NAME                              AS DEVICETYPENAME,
    DTI.DEVICE_TYPE_NAME                              AS DEVICETYPE,
    DTI.SPECIAL_TYPE_C                                AS DEVICESPECLIZATIONTYPECODE,
    ZST2.NAME                                         AS DEVICESPECLIZATIONTYPE,
    P.PAT_MRN_ID                                      AS MRN,
    P.PAT_NAME                                        AS PATIENTNAME,
    DI.HOSPITAL_ID                                    AS LOCATIONID,
    DI.DEVICE_IP                                      AS DEVICEIP,
    DI.DEVICE_DESC                                    AS DEVICEDESCRPTION
FROM P3F P3
JOIN PATIENT P
  ON P.PAT_ID = P3.PAT_ID
JOIN IP_DATA_STORE IDS
  ON IDS.PAT_ID = P.PAT_ID
JOIN DEVICE_INFO DI
  ON IDS.INPATIENT_DATA_ID = DI.CURRENT_INP_ID
LEFT JOIN ZC_DEL_STATUS ZDS
  ON ZDS.DEL_STATUS_C = DI.RECORD_STATE_C
LEFT JOIN DEVICE_TYPE_INFO DTI
  ON DTI.DEVICE_TYPE_ID = DI.DEVICE_TYPE_ID
LEFT JOIN ZC_SPECIAL_TYPE_2 ZST2
  ON ZST2.SPECIAL_TYPE_2_C = DTI.SPECIAL_TYPE_C;
