CREATE OR REPLACE TABLE
`careflow-healthcare-analytics.careflow.mart_case_summary` AS

WITH case_base AS (

  SELECT
    Case_ID,

    ANY_VALUE(Patient_ID) AS Patient_ID,
    ANY_VALUE(Patient_Gender) AS Patient_Gender,
    ANY_VALUE(Patient_Age) AS Patient_Age,
    ANY_VALUE(Patient_Race) AS Patient_Race,

    COUNT(*) AS Total_Events,

    COUNT(DISTINCT Activity) AS Unique_Activities,

    MIN(Event_Timestamp) AS Case_Start_Timestamp,

    MAX(Event_Timestamp) AS Case_End_Timestamp,

    TIMESTAMP_DIFF(
      MAX(Event_Timestamp),
      MIN(Event_Timestamp),
      MINUTE
    ) AS Case_Duration_Min,

    SUM(COALESCE(Waiting_Time_Min, 0))
      AS Total_Waiting_Time_Min,

    AVG(Waiting_Time_Min)
      AS Avg_Waiting_Time_Min,

    MAX(Waiting_Time_Min)
      AS Max_Waiting_Time_Min,

    SUM(COALESCE(Transition_Duration_Min, 0))
      AS Total_Transition_Duration_Min,

    AVG(Transition_Duration_Min)
      AS Avg_Transition_Duration_Min,

    SUM(COALESCE(Is_Rework_Event, 0))
      AS Rework_Event_Count,

    MAX(COALESCE(Is_Rework_Event, 0))
      AS Has_Rework,

    STRING_AGG(
      DISTINCT Event_Status,
      ', '
      ORDER BY Event_Status
    ) AS Event_Status_Summary

  FROM
    `careflow-healthcare-analytics.careflow.fct_healthcare_events`

  GROUP BY
    Case_ID
),

first_last_activity AS (

  SELECT
    Case_ID,

    ARRAY_AGG(
      Activity
      ORDER BY Event_Timestamp, Event_Order
      LIMIT 1
    )[SAFE_OFFSET(0)] AS First_Activity,

    ARRAY_AGG(
      Activity
      ORDER BY Event_Timestamp DESC, Event_Order DESC
      LIMIT 1
    )[SAFE_OFFSET(0)] AS Last_Activity

  FROM
    `careflow-healthcare-analytics.careflow.fct_healthcare_events`

  GROUP BY
    Case_ID
)

SELECT
  cb.Case_ID,
  cb.Patient_ID,

  cb.Patient_Gender,
  cb.Patient_Age,
  cb.Patient_Race,

  cb.Total_Events,
  cb.Unique_Activities,

  cb.Case_Start_Timestamp,
  cb.Case_End_Timestamp,
  cb.Case_Duration_Min,

  fla.First_Activity,
  fla.Last_Activity,

  cb.Total_Waiting_Time_Min,
  cb.Avg_Waiting_Time_Min,
  cb.Max_Waiting_Time_Min,

  cb.Total_Transition_Duration_Min,
  cb.Avg_Transition_Duration_Min,

  cb.Rework_Event_Count,
  cb.Has_Rework,

  cb.Event_Status_Summary

FROM
  case_base AS cb

LEFT JOIN
  first_last_activity AS fla
ON
  cb.Case_ID = fla.Case_ID

ORDER BY
  cb.Case_ID;

  ----- VALIDATION PART STARTED ----- 

  ---- Row count ----
SELECT COUNT(*) AS total_cases
FROM `careflow-healthcare-analytics.careflow.mart_case_summary`;

------ Duplicate Case_ID  -------
SELECT
  Case_ID,
  COUNT(*) AS cnt
FROM `careflow-healthcare-analytics.careflow.mart_case_summary`
GROUP BY Case_ID
HAVING COUNT(*) > 1;

---- NULL Case_ID ------
SELECT COUNT(*) AS null_case_id
FROM `careflow-healthcare-analytics.careflow.mart_case_summary`
WHERE Case_ID IS NULL;

----- Negative duration -------
SELECT COUNT(*) AS negative_duration
FROM `careflow-healthcare-analytics.careflow.mart_case_summary`
WHERE Case_Duration_Min < 0;

----- Negative waiting -------
SELECT COUNT(*) AS negative_waiting
FROM `careflow-healthcare-analytics.careflow.mart_case_summary`
WHERE Total_Waiting_Time_Min < 0;

----- Rework validation ------
SELECT
  Has_Rework,
  COUNT(*) AS case_count
FROM `careflow-healthcare-analytics.careflow.mart_case_summary`
GROUP BY Has_Rework
ORDER BY Has_Rework;

------- VALIDATION WORK COPLETED AND 'mart_case_summary file' ------