CREATE OR REPLACE TABLE
`careflow-healthcare-analytics.careflow.mart_activity_bottleneck`
AS

SELECT
  Activity,

  COUNT(*) AS Total_Events,

  COUNT(DISTINCT Case_ID) AS Total_Cases,

  ROUND(AVG(Waiting_Time_Min), 2) AS Avg_Waiting_Time_Min,

  ROUND(MIN(Waiting_Time_Min), 2) AS Min_Waiting_Time_Min,

  ROUND(MAX(Waiting_Time_Min), 2) AS Max_Waiting_Time_Min,

  ROUND(
    APPROX_QUANTILES(Waiting_Time_Min, 100)[OFFSET(50)],
    2
  ) AS Median_Waiting_Time_Min,

  COUNTIF(Waiting_Time_Min > 20) AS Events_Above_20_Min,

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
  Activity IS NOT NULL
  AND Waiting_Time_Min IS NOT NULL
  AND Waiting_Time_Min >= 0

GROUP BY
  Activity

ORDER BY
  Avg_Waiting_Time_Min DESC;



  -------  VALIDATION  ----------

  SELECT *
FROM `careflow-healthcare-analytics.careflow.mart_activity_bottleneck`
ORDER BY Avg_Waiting_Time_Min DESC;

---------Activity NULL
SELECT COUNT(*) AS Null_Activity_Count
FROM `careflow-healthcare-analytics.careflow.mart_activity_bottleneck`
WHERE Activity IS NULL;

 -----Negative waiting time
 SELECT COUNT(*) AS Negative_Waiting_Time_Count
FROM `careflow-healthcare-analytics.careflow.mart_activity_bottleneck`
WHERE Min_Waiting_Time_Min < 0;

-------Bottleneck logic check
SELECT
  Activity,
  Avg_Waiting_Time_Min,
  Bottleneck_Status
FROM `careflow-healthcare-analytics.careflow.mart_activity_bottleneck`
ORDER BY Avg_Waiting_Time_Min DESC;

----Source vs mart activity count

-----Source:

SELECT COUNT(DISTINCT Activity) AS Source_Activities
FROM `careflow-healthcare-analytics.careflow.fct_healthcare_events`
WHERE Activity IS NOT NULL;

------Mart:

SELECT COUNT(*) AS Mart_Activities
FROM `careflow-healthcare-analytics.careflow.mart_activity_bottleneck`;


SELECT
  Activity,
  Total_Events,
  Events_Above_20_Min,
  Percent_Events_Above_20_Min,

  ROUND(
    SAFE_DIVIDE(Events_Above_20_Min, Total_Events) * 100,
    2
  ) AS Recalculated_Percent_Above_20_Min

FROM `careflow-healthcare-analytics.careflow.mart_activity_bottleneck`

ORDER BY Percent_Events_Above_20_Min DESC;

---Bottleneck status
SELECT
  Activity,
  Avg_Waiting_Time_Min,
  Bottleneck_Status,

  CASE
    WHEN Avg_Waiting_Time_Min > 20 THEN 'BOTTLENECK'
    ELSE 'WITHIN_TARGET'
  END AS Expected_Status

FROM `careflow-healthcare-analytics.careflow.mart_activity_bottleneck`

WHERE Bottleneck_Status !=
  CASE
    WHEN Avg_Waiting_Time_Min > 20 THEN 'BOTTLENECK'
    ELSE 'WITHIN_TARGET'
  END;

------Department Bottleneck
  SELECT
  Department,
  COUNT(*) AS Total_Events,
  ROUND(SUM(Waiting_Time_Min), 2) AS Total_Waiting_Time_Min,
  ROUND(AVG(Waiting_Time_Min), 2) AS Avg_Waiting_Time_Min,
  ROUND(MAX(Waiting_Time_Min), 2) AS Max_Waiting_Time_Min,
  20 AS Target_Waiting_Time_Min,
  ROUND(AVG(Waiting_Time_Min) - 20, 2) AS Gap_Min,
  CASE
    WHEN AVG(Waiting_Time_Min) <= 20 THEN 'PASS'
    ELSE 'ABOVE TARGET'
  END AS Target_Status
FROM `careflow-healthcare-analytics.careflow.fct_healthcare_events`
WHERE Department IS NOT NULL
GROUP BY Department
ORDER BY Avg_Waiting_Time_Min DESC;
