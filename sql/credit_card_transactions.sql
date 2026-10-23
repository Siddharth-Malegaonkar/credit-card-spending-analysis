-- ============================================
-- CREDIT CARD SPENDING ANALYSIS
-- SQL Server
-- ============================================

-- 1. Create the database
CREATE DATABASE credit_card_analysis;
GO

USE credit_card_analysis;
GO


-- 2. Create the table
CREATE TABLE credit_card_transcations (
    transaction_id INT,
    city VARCHAR(100),
    transaction_date DATE,
    card_type VARCHAR(20),
    exp_type VARCHAR(50),
    gender CHAR(1),
    amount BIGINT
);
GO


-- 3. Check the table structure
SELECT *
FROM credit_card_transcations;
GO


-- ============================================
-- EXPLORATORY DATA ANALYSIS
-- ============================================

-- Q1. Total number of transactions
SELECT COUNT(*) AS total_transactions
FROM credit_card_transcations;


-- Q2. Total spending
SELECT SUM(amount) AS total_spending
FROM credit_card_transcations;


-- Q3. Spending by card type
SELECT
    card_type,
    SUM(amount) AS total_spending
FROM credit_card_transcations
GROUP BY card_type
ORDER BY total_spending DESC;


-- Q4. Spending by city
SELECT
    city,
    SUM(amount) AS total_spending
FROM credit_card_transcations
GROUP BY city
ORDER BY total_spending DESC;


-- Q5. Spending by expense type
SELECT
    exp_type,
    SUM(amount) AS total_spending
FROM credit_card_transcations
GROUP BY exp_type
ORDER BY total_spending DESC;


-- Q6. Spending by gender
SELECT
    gender,
    SUM(amount) AS total_spending
FROM credit_card_transcations
GROUP BY gender
ORDER BY total_spending DESC;


-- Q7. Monthly spending
SELECT
    YEAR(transaction_date) AS transaction_year,
    MONTH(transaction_date) AS transaction_month,
    SUM(amount) AS total_spending
FROM credit_card_transcations
GROUP BY
    YEAR(transaction_date),
    MONTH(transaction_date)
ORDER BY
    transaction_year,
    transaction_month;


-- Q8. Average transaction amount
SELECT AVG(CAST(amount AS DECIMAL(18,2))) AS average_transaction_amount
FROM credit_card_transcations;


-- Q9. Top 5 cities by spending
SELECT TOP 5
    city,
    SUM(amount) AS total_spending
FROM credit_card_transcations
GROUP BY city
ORDER BY total_spending DESC;


-- Q10. Highest transaction
SELECT TOP 1 *
FROM credit_card_transcations
ORDER BY amount DESC;