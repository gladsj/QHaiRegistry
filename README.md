Status of the Project

// currently running in local to test out queries and running successfully

1. Allergy: 71,841 rows: 1m 46s ✅
1. CarePlan: 55,530 rows: 37m 9s ✅
1. ClinicalResearch: 13,178 rows: 5s ✅
1. Device: Queries (1st and 2nd version) returning 0 rows ⚠️
1. Dialysis: 18,397 rows: 7s ✅
1. EpisodeOfCare: We can use it from ICD ✅
1. Immunization: Query works ✅, it just takes a long time to run 5 years of data. Check what we actually need. ⚠️ 
1. ImplantsAndSupplies: Need to Debug ❌ - We believe it's a different in datatype between the SUP and IMP subqueries that get UNION'ed together.
1. Infections: Need to Debug ❌ - We're not sure which column is causing the issue. Commenting out is creating new errors.
1. PatientAnsweredQuestions: 2,091,069 rows; 1m 36s ✅
1. RiskAssessment: Waiting for Suri to sent updated query ❌    
1. Social History: Query works ✅, it just takes a long time to run 2 years of data. Check what we actually need. ⚠️
