-- 1. Total Rows
SELECT COUNT(*) AS total_rows
FROM `careflow-healthcare-analytics.careflow.validation_table`;

-- 2. Distinct Case_ID
SELECT COUNT(DISTINCT Case_ID) AS distinct_case_id
FROM `careflow-healthcare-analytics.careflow.validation_table`;

-- 3. Duplicate Event_ID
SELECT
  Event_ID,
  COUNT(*) AS duplicate_count
FROM `careflow-healthcare-analytics.careflow.validation_table`
GROUP BY Event_ID
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;

-- 4. Duplicate Case_ID + Event_Order
SELECT
  Case_ID,
  Event_Order,
  COUNT(*) AS duplicate_count
FROM `careflow-healthcare-analytics.careflow.validation_table`
GROUP BY Case_ID, Event_Order
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;

-- 5. NULL Case_ID
SELECT COUNT(*) AS null_case_id
FROM `careflow-healthcare-analytics.careflow.validation_table`
WHERE Case_ID IS NULL;

-- 6. NULL Activity
SELECT COUNT(*) AS null_activity
FROM `careflow-healthcare-analytics.careflow.validation_table`
WHERE Activity IS NULL;

-- 7. NULL Timestamp
SELECT COUNT(*) AS null_timestamp
FROM `careflow-healthcare-analytics.careflow.validation_table`
WHERE Timestamp IS NULL;

-- 8. Negative Waiting_Time_Min
SELECT COUNT(*) AS negative_waiting_time
FROM `careflow-healthcare-analytics.careflow.validation_table`
WHERE Waiting_Time_Min < 0;