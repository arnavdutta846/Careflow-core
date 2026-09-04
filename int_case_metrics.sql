CREATE OR REPLACE TABLE
  `careflow-healthcare-analytics.careflow.int_case_metrics` AS
WITH case_data AS (

  SELECT
    Case_ID,
    Patient_ID,
    Activity,
    Event_Timestamp,
    Waiting_Time_Min,
    Next_Event_Timestamp

  FROM `careflow-healthcare-analytics.careflow.int_healthcare_events`

),

case_metrics AS (

  SELECT
    Case_ID,

    ANY_VALUE(Patient_ID) AS Patient_ID,

    MIN(Event_Timestamp) AS Case_Start_Timestamp,

    MAX(Event_Timestamp) AS Case_End_Timestamp,

    TIMESTAMP_DIFF(
      MAX(Event_Timestamp),
      MIN(Event_Timestamp),
      MINUTE
    ) AS Case_Duration_Min,

    COUNT(*) AS Total_Events,

    COUNT(DISTINCT Activity) AS Unique_Activities,

    SUM(COALESCE(Waiting_Time_Min, 0)) AS Total_Waiting_Time_Min,

    AVG(Waiting_Time_Min) AS Avg_Waiting_Time_Min,

    MAX(Waiting_Time_Min) AS Max_Waiting_Time_Min,

    COUNTIF(Next_Event_Timestamp IS NOT NULL) AS Total_Transitions

  FROM case_data

  GROUP BY Case_ID

),

repeated_activity AS (

  SELECT
    Case_ID,
    COUNT(*) AS Rework_Event_Count

  FROM (
    SELECT
      Case_ID,
      Activity

    FROM case_data

    GROUP BY
      Case_ID,
      Activity

    HAVING COUNT(*) > 1
  )

  GROUP BY Case_ID

)

SELECT
  cm.Case_ID,
  cm.Patient_ID,
  cm.Case_Start_Timestamp,
  cm.Case_End_Timestamp,
  cm.Case_Duration_Min,
  cm.Total_Events,
  cm.Unique_Activities,
  cm.Total_Waiting_Time_Min,
  cm.Avg_Waiting_Time_Min,
  cm.Max_Waiting_Time_Min,
  cm.Total_Transitions,
  COALESCE(ra.Rework_Event_Count, 0) AS Rework_Event_Count

FROM case_metrics AS cm

LEFT JOIN repeated_activity AS ra
  ON cm.Case_ID = ra.Case_ID

ORDER BY
  cm.Case_ID;

  ----CASE_METRICS VALIDATION AND CHECKING-----
  --- 1 — Total rows ---
  SELECT
  COUNT(*) AS total_cases
FROM `careflow-healthcare-analytics.careflow.int_case_metrics`;

--- 2 — Distinct Case_ID ---
SELECT
  COUNT(DISTINCT Case_ID) AS distinct_case_id
FROM `careflow-healthcare-analytics.careflow.int_case_metrics`;

--- 3 — Duplicate Case_ID ---
SELECT
  Case_ID,
  COUNT(*) AS row_count
FROM `careflow-healthcare-analytics.careflow.int_case_metrics`
GROUP BY Case_ID
HAVING COUNT(*) > 1
ORDER BY row_count DESC;

---4 — NULL Case_ID ---
SELECT
  COUNT(*) AS null_case_id
FROM `careflow-healthcare-analytics.careflow.int_case_metrics`
WHERE Case_ID IS NULL;

--- 5 — Negative Case Duration ---
SELECT
  COUNT(*) AS negative_case_duration
FROM `careflow-healthcare-analytics.careflow.int_case_metrics`
WHERE Case_Duration_Min < 0;

--- 6 — Negative Waiting Time ---
SELECT
  COUNT(*) AS negative_waiting_time
FROM `careflow-healthcare-analytics.careflow.int_case_metrics`
WHERE Total_Waiting_Time_Min < 0;

--- 7 — Sample output ---
SELECT *
FROM `careflow-healthcare-analytics.careflow.int_case_metrics`
ORDER BY Case_ID
LIMIT 20;

--- 8 — Schema check ---
SELECT
  column_name,
  data_type
FROM `careflow-healthcare-analytics.careflow.INFORMATION_SCHEMA.COLUMNS`
WHERE table_name = 'int_case_metrics'
ORDER BY ordinal_position;

---- VALIDATIONS ARE COMPLETED AND int_case_metrics file IS COMPLETED ---