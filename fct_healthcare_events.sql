CREATE OR REPLACE TABLE
`careflow-healthcare-analytics.careflow.fct_healthcare_events` AS
WITH event_base AS (

  SELECT
    Event_ID,
    Case_ID,
    Patient_ID,
    Event_Order,
    Activity,
    Department,
    Event_Date,
    Event_Time,
    Event_Timestamp,
    Patient_Gender,
    Patient_Age,
    Patient_Race,
    Department_Referral,
    Admission_Flag,
    Previous_Activity,
    Next_Activity,
    Next_Event_Timestamp,
    Waiting_Time_Min,
    Event_Status,
    Rework_Reason,
    Transition_Duration_Min

  FROM `careflow-healthcare-analytics.careflow.int_healthcare_events`

),

event_flags AS (

  SELECT
    *,

    CASE
      WHEN Event_Order = MIN(Event_Order) OVER (
        PARTITION BY Case_ID
      )
      THEN 1
      ELSE 0
    END AS Is_First_Event,

    CASE
      WHEN Event_Order = MAX(Event_Order) OVER (
        PARTITION BY Case_ID
      )
      THEN 1
      ELSE 0
    END AS Is_Last_Event,

    CASE
      WHEN COUNT(*) OVER (
        PARTITION BY Case_ID, Activity
        ORDER BY Event_Timestamp, Event_Order
        ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
      ) > 0
      THEN 1
      ELSE 0
    END AS Is_Rework_Event

  FROM event_base

)

SELECT
  Event_ID,
  Case_ID,
  Patient_ID,
  Event_Order,

  Activity,
  Department,

  Event_Date,
  Event_Time,
  Event_Timestamp,

  Patient_Gender,
  Patient_Age,
  Patient_Race,
  Department_Referral,
  Admission_Flag,

  Previous_Activity,
  Next_Activity,
  Next_Event_Timestamp,

  Waiting_Time_Min,
  Transition_Duration_Min,

  Event_Status,
  Rework_Reason,

  Is_First_Event,
  Is_Last_Event,
  Is_Rework_Event

FROM event_flags

ORDER BY
  Case_ID,
  Event_Order;

  ---- FCT_HEALTHCARE_FILE VALIDATION AND CHECKING -----
  
  --- Validation 1 — Total rows
  SELECT
  COUNT(*) AS total_events
FROM `careflow-healthcare-analytics.careflow.fct_healthcare_events`;

--- Validation 2 — Distinct Case_ID
SELECT
  COUNT(DISTINCT Case_ID) AS distinct_cases
FROM `careflow-healthcare-analytics.careflow.fct_healthcare_events`;

--- Validation 3 — Duplicate Event_ID
SELECT
  Event_ID,
  COUNT(*) AS event_count
FROM `careflow-healthcare-analytics.careflow.fct_healthcare_events`
GROUP BY Event_ID
HAVING COUNT(*) > 1
ORDER BY event_count DESC;

--- 10. Validation — Duplicate Case_ID + Event_Order
SELECT
  Case_ID,
  Event_Order,
  COUNT(*) AS row_count
FROM `careflow-healthcare-analytics.careflow.fct_healthcare_events`
GROUP BY
  Case_ID,
  Event_Order
HAVING COUNT(*) > 1
ORDER BY row_count DESC;

--- 11. Vslidation - NULL checks
SELECT
  COUNTIF(Event_ID IS NULL) AS null_event_id,
  COUNTIF(Case_ID IS NULL) AS null_case_id,
  COUNTIF(Activity IS NULL) AS null_activity,
  COUNTIF(Event_Timestamp IS NULL) AS null_event_timestamp
FROM `careflow-healthcare-analytics.careflow.fct_healthcare_events`;

--- 12. First/Last event validation ----
SELECT
  Case_ID,
  SUM(Is_First_Event) AS first_event_count,
  SUM(Is_Last_Event) AS last_event_count
FROM `careflow-healthcare-analytics.careflow.fct_healthcare_events`
GROUP BY Case_ID
HAVING
  SUM(Is_First_Event) != 1
  OR SUM(Is_Last_Event) != 1;

  --- 13. Negative time validation ---
  SELECT
  COUNTIF(Waiting_Time_Min < 0) AS negative_waiting_time,
  COUNTIF(Transition_Duration_Min < 0) AS negative_transition_duration
FROM `careflow-healthcare-analytics.careflow.fct_healthcare_events`;

--- 14. Schema validation ---
SELECT
  column_name,
  data_type
FROM `careflow-healthcare-analytics.careflow.INFORMATION_SCHEMA.COLUMNS`
WHERE table_name = 'fct_healthcare_events'
ORDER BY ordinal_position;

--- 15. Sample output ---
SELECT *
FROM `careflow-healthcare-analytics.careflow.fct_healthcare_events`
ORDER BY Case_ID, Event_Order
LIMIT 20;

------ COMPLETE THE VALIDATIONS AND COMPLETE THE 'fct_healthcare_events file' -------
