CREATE OR REPLACE TABLE
`careflow-healthcare-analytics.careflow.mart_transition_analysis`
AS

SELECT
  Previous_Activity,

  Activity,

  CONCAT(Previous_Activity, ' → ', Activity) AS Transition,

  COUNT(*) AS Transition_Count,

  COUNT(DISTINCT Case_ID) AS Total_Cases,

  ROUND(
    AVG(Waiting_Time_Min),
    2
  ) AS Avg_Waiting_Time_Min,

  ROUND(
    MIN(Waiting_Time_Min),
    2
  ) AS Min_Waiting_Time_Min,

  ROUND(
    MAX(Waiting_Time_Min),
    2
  ) AS Max_Waiting_Time_Min,

  ROUND(
    APPROX_QUANTILES(
      Waiting_Time_Min,
      100
    )[OFFSET(50)],
    2
  ) AS Median_Waiting_Time_Min,

  COUNTIF(
    Waiting_Time_Min > 20
  ) AS Events_Above_20_Min,

  ROUND(
    SAFE_DIVIDE(
      COUNTIF(Waiting_Time_Min > 20),
      COUNT(*)
    ) * 100,
    2
  ) AS Percent_Events_Above_20_Min,

  CASE
    WHEN AVG(Waiting_Time_Min) > 20
      THEN 'BOTTLENECK'
    ELSE 'WITHIN_TARGET'
  END AS Bottleneck_Status

FROM
`careflow-healthcare-analytics.careflow.fct_healthcare_events`

WHERE
  Previous_Activity IS NOT NULL
  AND Activity IS NOT NULL
  AND Waiting_Time_Min IS NOT NULL
  AND Waiting_Time_Min >= 0

GROUP BY
  Previous_Activity,
  Activity

ORDER BY
  Avg_Waiting_Time_Min DESC;


 ----- validaiton ------

 SELECT *
FROM `careflow-healthcare-analytics.careflow.mart_transition_analysis`
ORDER BY Avg_Waiting_Time_Min DESC;

-----NULL transition check
SELECT
  COUNT(*) AS Invalid_Transition_Count
FROM `careflow-healthcare-analytics.careflow.mart_transition_analysis`
WHERE
  Previous_Activity IS NULL
  OR Activity IS NULL
  OR Transition IS NULL;

--------  Negative waiting validation
SELECT
  COUNT(*) AS Negative_Waiting_Time_Count
FROM `careflow-healthcare-analytics.careflow.mart_transition_analysis`
WHERE Min_Waiting_Time_Min < 0;

-----Transition count validation

----Source:
SELECT
  COUNT(*) AS Source_Transition_Events
FROM `careflow-healthcare-analytics.careflow.fct_healthcare_events`
WHERE
  Previous_Activity IS NOT NULL
  AND Activity IS NOT NULL
  AND Waiting_Time_Min IS NOT NULL
  AND Waiting_Time_Min >= 0;
---Mart:
SELECT
  SUM(Transition_Count) AS Mart_Transition_Events
FROM `careflow-healthcare-analytics.careflow.mart_transition_analysis`;

--->20 min percentage validation
SELECT
  Previous_Activity,
  Activity,
  Transition_Count,
  Events_Above_20_Min,
  Percent_Events_Above_20_Min,

  ROUND(
    SAFE_DIVIDE(
      Events_Above_20_Min,
      Transition_Count
    ) * 100,
    2
  ) AS Recalculated_Percent_Above_20_Min

FROM
`careflow-healthcare-analytics.careflow.mart_transition_analysis`

ORDER BY
  Percent_Events_Above_20_Min DESC;

 --- Bottleneck logic validation
 SELECT
  Previous_Activity,
  Activity,
  Avg_Waiting_Time_Min,
  Bottleneck_Status,

  CASE
    WHEN Avg_Waiting_Time_Min > 20
      THEN 'BOTTLENECK'
    ELSE 'WITHIN_TARGET'
  END AS Expected_Status

FROM
`careflow-healthcare-analytics.careflow.mart_transition_analysis`

WHERE
  Bottleneck_Status !=
  CASE
    WHEN Avg_Waiting_Time_Min > 20
      THEN 'BOTTLENECK'
    ELSE 'WITHIN_TARGET'
  END;

 ---- Duplicate transition check
 SELECT
  Previous_Activity,
  Activity,
  COUNT(*) AS Duplicate_Rows
FROM
`careflow-healthcare-analytics.careflow.mart_transition_analysis`
GROUP BY
  Previous_Activity,
  Activity
HAVING COUNT(*) > 1;

SELECT
  Previous_Activity,
  Activity,
  Transition,
  Transition_Count,
  ROUND(Avg_Waiting_Time_Min, 2) AS Avg_Waiting_Time_Min
FROM `careflow-healthcare-analytics.careflow.mart_transition_analysis`
ORDER BY Avg_Waiting_Time_Min DESC;