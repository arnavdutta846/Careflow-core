--1.checking shcema of raw table 
SELECT
column_name,
data_type
FROM `careflow-healthcare-analytics.careflow.INFORMATION_SCHEMA.COLUMNS`
WHERE table_name = 'validation_table'
ORDER BY ordinal_position;

-- 2.checking the foremat of schema
SELECT
  Event_Date,
  COUNT(*) AS row_count
FROM `careflow-healthcare-analytics.careflow.validation_table`
GROUP BY Event_Date
ORDER BY Event_Date
LIMIT 20;

-- 3.Event_Time check
SELECT
  Event_Time,
  COUNT(*) AS row_count
FROM `careflow-healthcare-analytics.careflow.validation_table`
GROUP BY Event_Time
ORDER BY Event_Time
LIMIT 20;

-- 4.Timestamp check
SELECT
  Timestamp,
  COUNT(*) AS row_count
FROM `careflow-healthcare-analytics.careflow.validation_table`
GROUP BY Timestamp
ORDER BY Timestamp
LIMIT 20;

--- Numeric columns check ----
--- 5.Patient_Age check
SELECT
  Patient_Age
FROM `careflow-healthcare-analytics.careflow.validation_table`
LIMIT 20;

--- 6.checking the minimum waiting time 
SELECT
  Waiting_Time_Min
FROM `careflow-healthcare-analytics.careflow.validation_table`
LIMIT 20;

---7.Event_Order
SELECT
Event_Order
FROM `careflow-healthcare-analytics.careflow.validation_table`
LIMIT 20;

---checking the space in string column---
---8.trimmig the event id 
SELECT
  Event_ID,
  TRIM(Event_ID) AS trimmed_event_id
FROM `careflow-healthcare-analytics.careflow.validation_table`
LIMIT 20;

---9. Trimmig the activity id 
SELECT
  Activity,
  TRIM(Activity) AS trimmed_activity
FROM `careflow-healthcare-analytics.careflow.validation_table`
LIMIT 20;

--- 10.we complete the all checking and then we start transformation in staging ---
CREATE OR REPLACE TABLE
  `careflow-healthcare-analytics.careflow.stg_healthcare_events` AS
SELECT
  TRIM(Event_ID) AS Event_ID,
  TRIM(Case_ID) AS Case_ID,
  TRIM(Patient_ID) AS Patient_ID,

  Event_Order,

  TRIM(Activity) AS Activity,
  TRIM(Department) AS Department,

  Event_Date,

  Event_Time,

  Timestamp AS Event_Timestamp,

  TRIM(Patient_Gender) AS Patient_Gender,

  Patient_Age,

  TRIM(Patient_Race) AS Patient_Race,
  TRIM(Department_Referral) AS Department_Referral,

  Admission_Flag,

  TRIM(Previous_Activity) AS Previous_Activity,

  Waiting_Time_Min,

  TRIM(Event_Status) AS Event_Status,
  TRIM(Rework_Reason) AS Rework_Reason

FROM `careflow-healthcare-analytics.careflow.validation_table`;

---after creating transformation in staging then we created new table name stg_healthcare_events ---
---and then we testing staging validations so let started ----

SELECT *
FROM `careflow-healthcare-analytics.careflow.stg_healthcare_events`
LIMIT 20;

--- 11.rows count---
SELECT
  COUNT(*) AS total_rows
FROM `careflow-healthcare-analytics.careflow.stg_healthcare_events`;

---Distinct Case_ID check---
SELECT
  COUNT(DISTINCT Case_ID) AS distinct_case_id
FROM `careflow-healthcare-analytics.careflow.stg_healthcare_events`;

---12.Staging NULL check
SELECT
  COUNTIF(Case_ID IS NULL) AS null_case_id,
  COUNTIF(Activity IS NULL) AS null_activity,
  COUNTIF(Event_Timestamp IS NULL) AS null_event_timestamp
FROM `careflow-healthcare-analytics.careflow.stg_healthcare_events`;

---13.Schema verify
SELECT
  column_name,
  data_type
FROM `careflow-healthcare-analytics.careflow.INFORMATION_SCHEMA.COLUMNS`
WHERE table_name = 'stg_healthcare_events'
ORDER BY ordinal_position;

-------staging wrok completed------
