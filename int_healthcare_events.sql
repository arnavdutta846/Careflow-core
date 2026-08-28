CREATE OR REPLACE TABLE
`careflow-healthcare-analytics.careflow.int_healthcare_events` AS

WITH event_data AS (

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
    Rework_Reason,
    Waiting_Time_Min,
    Event_Status

  FROM `careflow-healthcare-analytics.careflow.stg_healthcare_events`

),

event_sequence AS (

  SELECT
    *,
    
    LAG(Activity) OVER (
      PARTITION BY Case_ID
      ORDER BY Event_Timestamp, Event_Order
    ) AS Previous_Activity,

    LEAD(Activity) OVER (
      PARTITION BY Case_ID
      ORDER BY Event_Timestamp, Event_Order
    ) AS Next_Activity,

    LEAD(Event_Timestamp) OVER (
      PARTITION BY Case_ID
      ORDER BY Event_Timestamp, Event_Order
    ) AS Next_Event_Timestamp

  FROM event_data

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
  Rework_Reason,
  Waiting_Time_Min,
  Event_Status,

  Previous_Activity,
  Next_Activity,
  Next_Event_Timestamp,

  TIMESTAMP_DIFF(
    Next_Event_Timestamp,
    Event_Timestamp,
    MINUTE
  ) AS Transition_Duration_Min

FROM event_sequence

ORDER BY Case_ID, Event_Order;


SELECT *
FROM `careflow-healthcare-analytics.careflow.int_healthcare_events`
LIMIT 50;

SELECT
  COUNT(*) AS total_rows,
  COUNT(DISTINCT Case_ID) AS total_cases
FROM `careflow-healthcare-analytics.careflow.int_healthcare_events`;
