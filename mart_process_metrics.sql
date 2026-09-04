CREATE OR REPLACE TABLE
`careflow-healthcare-analytics.careflow.mart_process_metrics` AS

WITH process_summary AS (

  SELECT

    COUNT(*) AS Total_Cases,

    SUM(Total_Events) AS Total_Events,

    SAFE_DIVIDE(
      SUM(Total_Events),
      COUNT(*)
    ) AS Avg_Events_Per_Case,

    AVG(Case_Duration_Min) AS Avg_Case_Duration_Min,

    MIN(Case_Duration_Min) AS Min_Case_Duration_Min,

    MAX(Case_Duration_Min) AS Max_Case_Duration_Min,

    SUM(Total_Waiting_Time_Min)
      AS Total_Waiting_Time_Min,

    SAFE_DIVIDE(
      SUM(Total_Waiting_Time_Min),
      COUNT(*)
    ) AS Avg_Waiting_Time_Per_Case_Min,

    SAFE_DIVIDE(
      SUM(Total_Waiting_Time_Min),
      SUM(Total_Events)
    ) AS Avg_Event_Waiting_Time_Min,

    MAX(Max_Waiting_Time_Min)
      AS Max_Event_Waiting_Time_Min,

    SUM(Total_Transition_Duration_Min)
      AS Total_Transition_Duration_Min,

    SAFE_DIVIDE(
      SUM(Total_Transition_Duration_Min),
      COUNT(*)
    ) AS Avg_Transition_Duration_Per_Case_Min,

    SAFE_DIVIDE(
      SUM(Total_Transition_Duration_Min),
      SUM(Total_Events)
    ) AS Avg_Transition_Duration_Per_Event_Min,

    SUM(Rework_Event_Count)
      AS Total_Rework_Events,

    COUNTIF(Has_Rework = 1)
      AS Rework_Cases,

    SAFE_DIVIDE(
      COUNTIF(Has_Rework = 1) * 100,
      COUNT(*)
    ) AS Rework_Rate_Percent,

    COUNTIF(
      Event_Status_Summary = 'Completed'
    ) AS Completed_Cases,

    COUNTIF(
      Event_Status_Summary IS NULL
      OR Event_Status_Summary != 'Completed'
    ) AS Non_Completed_Cases,

    SAFE_DIVIDE(
      COUNTIF(Event_Status_Summary = 'Completed') * 100,
      COUNT(*)
    ) AS Completion_Rate_Percent

  FROM
    `careflow-healthcare-analytics.careflow.mart_case_summary`
)

SELECT
  Total_Cases,
  Total_Events,
  Avg_Events_Per_Case,

  Avg_Case_Duration_Min,
  Min_Case_Duration_Min,
  Max_Case_Duration_Min,

  Total_Waiting_Time_Min,
  Avg_Waiting_Time_Per_Case_Min,
  Avg_Event_Waiting_Time_Min,
  Max_Event_Waiting_Time_Min,

  Total_Transition_Duration_Min,
  Avg_Transition_Duration_Per_Case_Min,
  Avg_Transition_Duration_Per_Event_Min,

  Total_Rework_Events,
  Rework_Cases,
  Rework_Rate_Percent,

  Completed_Cases,
  Non_Completed_Cases,
  Completion_Rate_Percent

FROM process_summary;


--------- VALIDATIONS -------------
-----table row count
SELECT COUNT(*) AS row_count
FROM `careflow-healthcare-analytics.careflow.mart_process_metrics`;

-----total events
SELECT
  Total_Events
FROM `careflow-healthcare-analytics.careflow.mart_process_metrics`;

-----rework consistency
SELECT
  Total_Rework_Events,
  Rework_Cases,
  Rework_Rate_Percent
FROM `careflow-healthcare-analytics.careflow.mart_process_metrics`;

-------impossible negative values
SELECT *
FROM `careflow-healthcare-analytics.careflow.mart_process_metrics`
WHERE
  Total_Cases < 0
  OR Total_Events < 0
  OR Avg_Case_Duration_Min < 0
  OR Min_Case_Duration_Min < 0
  OR Max_Case_Duration_Min < 0
  OR Total_Waiting_Time_Min < 0
  OR Total_Transition_Duration_Min < 0;

  ------Waiting vs Transition total directly compare
  SELECT
  SUM(Waiting_Time_Min) AS Total_Waiting,
  SUM(Transition_Duration_Min) AS Total_Transition,
  SUM(Waiting_Time_Min) - SUM(Transition_Duration_Min) AS Difference
FROM `careflow-healthcare-analytics.careflow.fct_healthcare_events`;

-------Case duration vs waiting/transition check
SELECT
  SUM(Case_Duration_Min) AS Total_Case_Duration,
  SUM(Total_Waiting_Time_Min) AS Total_Waiting,
  SUM(Total_Transition_Duration_Min) AS Total_Transition
FROM `careflow-healthcare-analytics.careflow.mart_case_summary`;

------ Individual rows mein difference verify

SELECT
  COUNT(*) AS Total_Events,
  COUNTIF(
    Waiting_Time_Min != Transition_Duration_Min
  ) AS Different_Values
FROM `careflow-healthcare-analytics.careflow.fct_healthcare_events`;


SELECT
  ROUND(AVG(Waiting_Time_Min), 2) AS Overall_Avg_Event_Waiting_Time_Min,
  20 AS Target_Waiting_Time_Min,
  ROUND(AVG(Waiting_Time_Min) - 20, 2) AS Gap_Min,
  CASE
    WHEN AVG(Waiting_Time_Min) <= 20 THEN 'PASS'
    ELSE 'ABOVE TARGET'
  END AS Target_Status
FROM `careflow-healthcare-analytics.careflow.fct_healthcare_events`;

