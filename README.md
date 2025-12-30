*Status of the Project*

## Phase 1. Run Queries Locally to Test Successful Execution

1. ✅ Allergy: 71,841 rows: 1m 46s
1. ✅ CarePlan: 55,530 rows: 37m 9s
1. ✅ ClinicalResearch: 13,178 rows: 5s
1. ❌ Device: Query returning 0 rows (both the 1st and 2nd version sent)
1. ✅ Dialysis: 18,397 rows: 7s 
1. ✅ EpisodeOfCare: Re-use what we pulled from ICD
1. ⚠️ Immunization: Query works ✅, it just takes a long time to run 5 years of data. Check what we actually need.  
1. ❌ ImplantsAndSupplies: Need to Debug. We believe it's a different in datatype between the SUP and IMP subqueries that get UNION'ed together.
1. ❌ Infections: Need to Debug. We're not sure which column is causing the issue. Commenting out is creating new errors.
1. ✅ PatientAnsweredQuestions: 2,091,069 rows; 1m 36s
1. ⚠️ RiskAssessment: Waiting for Suri to sent updated query     
1. ⚠️ Social History: Query works ✅, it just takes a long time to run 2 years of data. Check what we actually need. ⚠️

## Phase 2. Put Queries in Notebooks to Extract, Zip, and Transfer Data to Azure Bucket

⚠️ **NOTE: Many of these don't need a notebook that loops through chunks of time because they return all data in a short amount of time (minutes as opposed to hours)** 

1. Allergy: 
1. CarePlan: 
1. ClinicalResearch: 
1. Device: 
1. Dialysis: 
1. EpisodeOfCare: 
1. Immunization: 
1. ImplantsAndSupplies: 
1. Infections: 
1. PatientAnsweredQuestions: 
1. RiskAssessment: 
1. Social History: 
