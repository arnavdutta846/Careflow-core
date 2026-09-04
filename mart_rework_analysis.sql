CREATE OR REPLACE TABLE
`careflow-healthcare-analytics.careflow.mart_rework_analysis` AS

WITH rework_summary AS (

  SELECT
    Activity,

    COUNT(*) AS Total_Events,

    COUNTIF(Is_Rework_Event = 1) AS Rework_Events,

    COUNT(DISTINCT Case_ID) AS Total_Cases,

    COUNT(DISTINCT CASE
      WHEN Is_Rework_Event = 1 THEN Case_ID
    END) AS Cases_With_Rework,

    SUM(
      CASE
        WHEN Is_Rework_Event = 1
        THEN 1
        ELSE 0
      END
    ) AS Rework_Event_Count

  FROM `careflow-healthcare-analytics.careflow.fct_healthcare_events`

  GROUP BY Activity

)

SELECT
  Activity,
  Total_Events,
  Rework_Events,
  Total_Cases,
  Cases_With_Rework,

  SAFE_DIVIDE(
    Rework_Events,
    Total_Events
  ) * 100 AS Rework_Rate_Percent,

  SAFE_DIVIDE(
    Cases_With_Rework,
    Total_Cases
  ) * 100 AS Case_Rework_Rate_Percent,

  Rework_Event_Count

FROM rework_summary

ORDER BY Rework_Rate_Percent DESC;


----- validation------
--------Duplicate Activity
SELECT
  Activity,
  COUNT(*) AS row_count
FROM `careflow-healthcare-analytics.careflow.mart_rework_analysis`
GROUP BY Activity
HAVING COUNT(*) > 1;

----NULL Activity
SELECT
  COUNT(*) AS null_activity
FROM `careflow-healthcare-analytics.careflow.mart_rework_analysis`
WHERE Activity IS NULL;

-----Rework events cannot exceed total events
SELECT
  COUNT(*) AS invalid_rows
FROM `careflow-healthcare-analytics.careflow.mart_rework_analysis`
WHERE Rework_Events > Total_Events;

----Rework rate range
SELECT
  COUNT(*) AS invalid_rework_rate
FROM `careflow-healthcare-analytics.careflow.mart_rework_analysis`
WHERE Rework_Rate_Percent < 0
   OR Rework_Rate_Percent > 100;

-------Case rework rate range
SELECT
  COUNT(*) AS invalid_case_rework_rate
FROM `careflow-healthcare-analytics.careflow.mart_rework_analysis`
WHERE Case_Rework_Rate_Percent < 0
   OR Case_Rework_Rate_Percent > 100;

-----Schema validation 
SELECT
  column_name,
  data_type
FROM `careflow-healthcare-analytics.careflow.INFORMATION_SCHEMA.COLUMNS`
WHERE table_name = 'mart_rework_analysis'
ORDER BY ordinal_position;

----Sample output
SELECT *
FROM `careflow-healthcare-analytics.careflow.mart_rework_analysis`
ORDER BY Rework_Rate_Percent DESC
LIMIT 20;

---------Rework + Bottleneck comparison
SELECT
  b.Activity,

  ROUND(b.Avg_Waiting_Time_Min, 2) AS Avg_Waiting_Time_Min,

  ROUND(r.Rework_Rate_Percent, 2) AS Rework_Rate_Percent,

  ROUND(r.Case_Rework_Rate_Percent, 2) AS Case_Rework_Rate_Percent,

  b.Total_Events,

  r.Rework_Events,

  CASE
    WHEN b.Avg_Waiting_Time_Min > 20
         AND r.Rework_Rate_Percent > 0
      THEN 'Waiting + Rework'
    WHEN b.Avg_Waiting_Time_Min > 20
      THEN 'Waiting Bottleneck'
    WHEN r.Rework_Rate_Percent > 0
      THEN 'Rework'
    ELSE 'Normal'
  END AS Bottleneck_Type

FROM `careflow-healthcare-analytics.careflow.mart_activity_bottleneck` b

LEFT JOIN
  `careflow-healthcare-analytics.careflow.mart_rework_analysis` r

ON b.Activity = r.Activity

ORDER BY
  b.Avg_Waiting_Time_Min DESC;