-- ============================================
-- CREDIT CARD SPENDING ANALYSIS
-- Business Questions
-- SQL Server
-- ============================================

USE credit_card_analysis;
GO


-- ============================================
-- Q1. Top 5 cities with highest spends and
--     percentage contribution to total spends
-- ============================================

SELECT TOP 5
    city,
    SUM(amount) AS total_spends,
    CAST(
        SUM(amount) * 100.0 /
        (SELECT SUM(amount)
         FROM credit_card_transcations)
        AS DECIMAL(10, 2)
    ) AS percentage_contribution
FROM credit_card_transcations
GROUP BY city
ORDER BY total_spends DESC;


-- ============================================
-- Q2. Highest spend month and amount for
--     each card type
-- ============================================

WITH monthly_spends AS (
    SELECT
        card_type,
        YEAR(transaction_date) AS spend_year,
        MONTH(transaction_date) AS spend_month,
        SUM(amount) AS total_spends
    FROM credit_card_transcations
    GROUP BY
        card_type,
        YEAR(transaction_date),
        MONTH(transaction_date)
),
ranked_spends AS (
    SELECT
        card_type,
        spend_year,
        spend_month,
        total_spends,
        RANK() OVER (
            PARTITION BY card_type
            ORDER BY total_spends DESC
        ) AS spend_rank
    FROM monthly_spends
)
SELECT
    card_type,
    spend_year,
    spend_month,
    total_spends
FROM ranked_spends
WHERE spend_rank = 1
ORDER BY card_type;


-- ============================================
-- Q3. Transaction details when cumulative
--     spending reaches 1,000,000 per card type
-- ============================================

WITH cumulative_spends AS (
    SELECT
        *,
        SUM(amount) OVER (
            PARTITION BY card_type
            ORDER BY transaction_date, transaction_id
            ROWS BETWEEN UNBOUNDED PRECEDING
                     AND CURRENT ROW
        ) AS running_total
    FROM credit_card_transcations
),
threshold_transactions AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY card_type
            ORDER BY transaction_date, transaction_id
        ) AS threshold_rank
    FROM cumulative_spends
    WHERE running_total >= 1000000
)
SELECT
    transaction_id,
    city,
    transaction_date,
    card_type,
    exp_type,
    gender,
    amount
FROM threshold_transactions
WHERE threshold_rank = 1
ORDER BY card_type;


-- ============================================
-- Q4. City with the lowest percentage spend
--     for Gold card type
-- ============================================

WITH gold_city_spends AS (
    SELECT
        city,
        SUM(amount) AS total_spends
    FROM credit_card_transcations
    WHERE card_type = 'Gold'
    GROUP BY city
)
SELECT TOP 1
    city,
    total_spends,
    CAST(
        total_spends * 100.0 /
        SUM(total_spends) OVER ()
        AS DECIMAL(10, 2)
    ) AS percentage_spends
FROM gold_city_spends
ORDER BY total_spends ASC;


-- ============================================
-- Q5. Highest and lowest expense type
--     for each city
-- ============================================

WITH expense_spends AS (
    SELECT
        city,
        exp_type,
        SUM(amount) AS total_spends
    FROM credit_card_transcations
    GROUP BY city, exp_type
),
ranked_expenses AS (
    SELECT
        city,
        exp_type,
        total_spends,
        ROW_NUMBER() OVER (
            PARTITION BY city
            ORDER BY total_spends DESC, exp_type
        ) AS highest_rank,
        ROW_NUMBER() OVER (
            PARTITION BY city
            ORDER BY total_spends ASC, exp_type
        ) AS lowest_rank
    FROM expense_spends
)
SELECT
    highest.city,
    highest.exp_type AS highest_expense_type,
    lowest.exp_type AS lowest_expense_type
FROM ranked_expenses AS highest
JOIN ranked_expenses AS lowest
    ON highest.city = lowest.city
WHERE highest.highest_rank = 1
  AND lowest.lowest_rank = 1
ORDER BY highest.city;


-- ============================================
-- Q6. Percentage contribution of female spends
--     for each expense type
-- ============================================

SELECT
    exp_type,
    SUM(
        CASE
            WHEN gender = 'F' THEN amount
            ELSE 0
        END
    ) AS female_spends,
    SUM(amount) AS total_spends,
    CAST(
        SUM(
            CASE
                WHEN gender = 'F' THEN amount
                ELSE 0
            END
        ) * 100.0 /
        NULLIF(SUM(amount), 0)
        AS DECIMAL(10, 2)
    ) AS female_percentage
FROM credit_card_transcations
GROUP BY exp_type
ORDER BY female_percentage DESC;


-- ============================================
-- Q7. Card and expense type with the highest
--     month-over-month growth in January 2014
-- ============================================

WITH monthly_spends AS (
    SELECT
        card_type,
        exp_type,
        YEAR(transaction_date) AS spend_year,
        MONTH(transaction_date) AS spend_month,
        SUM(amount) AS total_spends
    FROM credit_card_transcations
    WHERE transaction_date >= '20131201'
      AND transaction_date < '20140201'
    GROUP BY
        card_type,
        exp_type,
        YEAR(transaction_date),
        MONTH(transaction_date)
),
growth_calculation AS (
    SELECT
        card_type,
        exp_type,
        SUM(
            CASE
                WHEN spend_year = 2013
                 AND spend_month = 12
                THEN total_spends
                ELSE 0
            END
        ) AS december_spends,
        SUM(
            CASE
                WHEN spend_year = 2014
                 AND spend_month = 1
                THEN total_spends
                ELSE 0
            END
        ) AS january_spends
    FROM monthly_spends
    GROUP BY card_type, exp_type
)
SELECT TOP 1
    card_type,
    exp_type,
    december_spends,
    january_spends,
    CAST(
        (january_spends - december_spends) * 100.0 /
        NULLIF(december_spends, 0)
        AS DECIMAL(10, 2)
    ) AS growth_percentage
FROM growth_calculation
WHERE december_spends > 0
ORDER BY growth_percentage DESC;


-- ============================================
-- Q9. City with the highest weekend spending
--     to transaction count ratio
-- ============================================

SELECT TOP 1
    city,
    SUM(amount) AS total_weekend_spends,
    COUNT(*) AS total_weekend_transactions,
    CAST(
        SUM(amount) * 1.0 / COUNT(*)
        AS DECIMAL(10, 2)
    ) AS spend_per_transaction
FROM credit_card_transcations
WHERE DATEDIFF(
          DAY,
          '19000101',
          transaction_date
      ) % 7 IN (5, 6)
GROUP BY city
ORDER BY spend_per_transaction DESC;


-- ============================================
-- Q10. City that took the fewest days to reach
--      its 500th transaction after its first
-- ============================================

WITH ranked_transactions AS (
    SELECT
        city,
        transaction_date,
        transaction_id,
        ROW_NUMBER() OVER (
            PARTITION BY city
            ORDER BY transaction_date, transaction_id
        ) AS transaction_number
    FROM credit_card_transcations
),
city_transaction_dates AS (
    SELECT
        city,
        MIN(
            CASE
                WHEN transaction_number = 1
                THEN transaction_date
            END
        ) AS first_transaction_date,
        MIN(
            CASE
                WHEN transaction_number = 500
                THEN transaction_date
            END
        ) AS transaction_500_date
    FROM ranked_transactions
    GROUP BY city
)
SELECT TOP 1
    city,
    first_transaction_date,
    transaction_500_date,
    DATEDIFF(
        DAY,
        first_transaction_date,
        transaction_500_date
    ) AS days_to_500th_transaction
FROM city_transaction_dates
WHERE transaction_500_date IS NOT NULL
ORDER BY days_to_500th_transaction ASC;
