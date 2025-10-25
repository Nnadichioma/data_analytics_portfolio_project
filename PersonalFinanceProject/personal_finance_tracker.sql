-- ==============================================
-- 1. CREATE DATABASE & USE
-- ==============================================
CREATE DATABASE IF NOT EXISTS FinanceDB;
USE FinanceDB;

-- ==============================================
-- 2. CREATE CATEGORY TABLE
-- ==============================================
DROP TABLE IF EXISTS Categories;
CREATE TABLE Categories (
    CategoryID INT AUTO_INCREMENT PRIMARY KEY,
    CategoryName VARCHAR(50) NOT NULL UNIQUE
);

INSERT INTO Categories (CategoryName) VALUES
('Income'),
('Rent'),
('Utilities'),
('Groceries'),
('Essentials'),
('Personal'),
('Transport');

-- ==============================================
-- 3. CREATE SUBCATEGORY TABLE
-- ==============================================
DROP TABLE IF EXISTS Subcategories;
CREATE TABLE Subcategories (
    SubcatID INT AUTO_INCREMENT PRIMARY KEY,
    SubcatName VARCHAR(100) NOT NULL,
    CategoryID INT NOT NULL,
    FOREIGN KEY (CategoryID) REFERENCES Categories(CategoryID)
);

INSERT INTO Subcategories (SubcatName, CategoryID) VALUES
('Salary / Reimbursement', 1),   -- Income
('Rent', 2),                     -- Rent
('Mobile / Data', 3),            -- Utilities
('Exchange', 3),                 -- Utilities
('Shopping', 4),                 -- Groceries
('Essentials General', 5),       -- Essentials
('Friends & Family', 6),         -- Personal
('Fare / Travel', 7);            -- Transport

-- ==============================================
-- 4. CREATE TRANSACTION TABLES
-- ==============================================
DROP TABLE IF EXISTS Transactions;
CREATE TABLE Transactions (
    TransID INT AUTO_INCREMENT PRIMARY KEY,
    TransDate DATE NOT NULL,
    Description VARCHAR(255),
    AmountIn DECIMAL(12,2) DEFAULT 0,
    AmountOut DECIMAL(12,2) DEFAULT 0,
    Balance DECIMAL(12,2),
    SubcatID INT NOT NULL,
    FOREIGN KEY (SubcatID) REFERENCES Subcategories(SubcatID)
);

-- STAGING TABLE (raw Excel/PDF imports before cleaning)
DROP TABLE IF EXISTS StagingTransactions;
CREATE TABLE StagingTransactions (
    TransDate VARCHAR(20),
    Description VARCHAR(255),
    Type VARCHAR(20),
    AmountIn VARCHAR(20),
    AmountOut VARCHAR(20),
    Balance VARCHAR(20),
    CategoryName VARCHAR(100),
    SubcatName VARCHAR(100),
    SubcatID INT
);

-- ==============================================
-- 5. DATA CLEANING (StagingTransactions)
-- ==============================================

-- Blank to NULL
UPDATE StagingTransactions
SET AmountIn = NULL WHERE AmountIn = '';
UPDATE StagingTransactions
SET AmountOut = NULL WHERE AmountOut = '';
UPDATE StagingTransactions
SET Balance = NULL WHERE Balance = '';
UPDATE StagingTransactions
SET TransDate = NULL WHERE TransDate = '';

-- Convert Excel serial dates to proper DATE
UPDATE StagingTransactions
SET TransDate = DATE_ADD('1899-12-30', INTERVAL CAST(TransDate AS UNSIGNED) DAY)
WHERE TransDate REGEXP '^[0-9]+$';

ALTER TABLE StagingTransactions MODIFY COLUMN TransDate DATE;

-- Remove currency symbols/commas
UPDATE StagingTransactions
SET AmountIn = REPLACE(REPLACE(AmountIn, '$', ''), ',', ''),
    AmountOut = REPLACE(REPLACE(AmountOut, '$', ''), ',', ''),
    Balance = REPLACE(REPLACE(Balance, '$', ''), ',', '');

-- Convert to DECIMAL
ALTER TABLE StagingTransactions
MODIFY COLUMN AmountIn DECIMAL(12,2),
MODIFY COLUMN AmountOut DECIMAL(12,2),
MODIFY COLUMN Balance DECIMAL(12,2);

-- Standardize text fields
UPDATE StagingTransactions
SET 
    Description = TRIM(REPLACE(Description, '.', '')),
    Type = TRIM(REPLACE(Type, '.', '')),
    CategoryName = TRIM(REPLACE(CategoryName, '.', '')),
    SubcatName = TRIM(REPLACE(SubcatName, '.', ''));

-- Map Subcategories
UPDATE StagingTransactions s
JOIN Subcategories sub ON s.SubcatName = sub.SubcatName
SET s.SubcatID = sub.SubcatID;

-- Assign "Other" for unmapped subcategories
INSERT INTO Subcategories (SubcatName, CategoryID)
VALUES ('Other', 5)  -- Essentials default
ON DUPLICATE KEY UPDATE SubcatName = SubcatName;

UPDATE StagingTransactions s
JOIN Subcategories sub ON s.SubcatName = sub.SubcatName
SET s.SubcatID = sub.SubcatID
WHERE s.SubcatID IS NULL;

-- ==============================================
-- 6. LOAD CLEAN DATA INTO TRANSACTIONS
-- ==============================================
INSERT INTO Transactions (TransDate, Description, AmountIn, AmountOut, Balance, SubcatID)
SELECT TransDate, Description, AmountIn, AmountOut, Balance, SubcatID
FROM StagingTransactions;

-- ==============================================
-- 7. ANALYSIS QUERIES
-- ==============================================

-- 7.1 Monthly Spending
SELECT 
    MONTH(TransDate) AS Month,
    SUM(AmountOut) AS TotalSpending
FROM Transactions
GROUP BY MONTH(TransDate)
ORDER BY Month;

-- 7.2 Monthly Income
SELECT 
    MONTH(TransDate) AS Month,
    SUM(AmountIn) AS TotalIncome
FROM Transactions
GROUP BY MONTH(TransDate)
ORDER BY Month;

-- 7.3 Spending by Category per Month
SELECT 
    MONTH(t.TransDate) AS Month,
    c.CategoryName,
    SUM(t.AmountOut) AS TotalSpending
FROM Transactions t
JOIN Subcategories s ON t.SubcatID = s.SubcatID
JOIN Categories c ON s.CategoryID = c.CategoryID
GROUP BY MONTH(t.TransDate), c.CategoryName
ORDER BY Month, c.CategoryName;

-- 7.4 Spending by Subcategory
SELECT 
    s.SubcatName,
    c.CategoryName,
    SUM(t.AmountOut) AS TotalSpending
FROM Transactions t
JOIN Subcategories s ON t.SubcatID = s.SubcatID
JOIN Categories c ON s.CategoryID = c.CategoryID
GROUP BY s.SubcatName, c.CategoryName
ORDER BY TotalSpending DESC;

-- 7.5 Savings Percentage
SELECT 
    MONTH(TransDate) AS Month,
    (SUM(AmountIn) - SUM(AmountOut)) / SUM(AmountIn) * 100 AS PercentageSaved
FROM Transactions
GROUP BY MONTH(TransDate)
ORDER BY Month;

-- 7.6 Balance Status by Day
SELECT 
    TransDate,
    Balance,
    CASE 
        WHEN Balance < 50 THEN 'Low'
        WHEN Balance BETWEEN 50 AND 100 THEN 'Medium'
        ELSE 'High'
    END AS BalanceStatus
FROM Transactions
ORDER BY TransDate;

-- 7.7 Any refunds or reimbursements to account for?
SELECT 
    t.TransDate,
    t.Description,
    s.SubcatName,
    t.AmountIn,
    t.AmountOut
FROM Transactions AS t
JOIN Subcategories AS s
	ON t.SubcatID = s.SubcatID
WHERE SubcatName LIKE '%Reimbursement%' OR AmountOut < 0
ORDER BY TransDate DESC;

-- 7.8 Any duplicate or suspicious entries?
SELECT 
    TransDate,
    Description,
    AmountOut,
    COUNT(*) AS Occurrences
FROM Transactions
GROUP BY TransDate, Description, AmountOut
HAVING COUNT(*) > 1
ORDER BY Occurrences DESC;

-- 7.9 Are there unusual spikes or one-off transactions that need explanation?
SELECT 
    t.TransDate,
    t.Description,
    s.SubcatName,
    t.AmountOut,
    AVG(t2.AmountOut) AS AvgSubcatSpending
FROM Transactions t
JOIN Subcategories s ON t.SubcatID = s.SubcatID
JOIN Transactions t2 ON t2.SubcatID = t.SubcatID
GROUP BY t.TransDate, t.Description, s.SubcatName, t.AmountOut
HAVING t.AmountOut > 2 * AVG(t2.AmountOut)
ORDER BY t.TransDate DESC;

-- 7.10 Patterns of overspending right after receiving income
SELECT 
    t1.TransDate AS IncomeDate,
    t1.AmountIn AS IncomeAmount,
    t2.TransDate AS SpendingDate,
    t2.AmountOut AS SpendingAmount,
    DATEDIFF(t2.TransDate, t1.TransDate) AS DaysAfterIncome
FROM Transactions t1
JOIN Transactions t2 
    ON t2.TransDate > t1.TransDate
WHERE t1.AmountIn > 0
ORDER BY t1.TransDate, t2.TransDate;

-- 7.11 Are there patterns of overspending right after receiving income? How often do I have negative or near-zero balances, if any?
SELECT 
    MONTH(TransDate) AS Month,
    COUNT(*) AS LowBalanceDays
FROM Transactions
WHERE Balance <= 0
GROUP BY MONTH(TransDate)
ORDER BY Month;
-- One Day in the Month of August

-- 7.12 Based on historical spending, can I estimate my expected expenses for the next month?
SELECT 
    s.SubcatName,
    c.CategoryName,
    AVG(t.AmountOut) AS AvgMonthlySpending
FROM Transactions t
JOIN Subcategories s ON t.SubcatID = s.SubcatID
JOIN Categories c ON s.CategoryID = c.CategoryID
GROUP BY c.CategoryName, s.SubcatName
ORDER BY c.CategoryName, s.SubcatName;

-- 7.13 Which categories are predictable vs irregular (e.g., rent is fixed, entertainment varies)?
-- check the standard deviation of spending per category per month. Low SD = Predictable, High SD = Irregular
SELECT 
    c.CategoryName,
    MONTH(t.TransDate) AS Month,
    SUM(t.AmountOut) AS TotalSpent,
    STDDEV(t.AmountOut) AS SpendingVariation
FROM Transactions t
JOIN Subcategories s ON t.SubcatID = s.SubcatID
JOIN Categories c ON s.CategoryID = c.CategoryID
GROUP BY c.CategoryName, MONTH(t.TransDate)
ORDER BY c.CategoryName, Month;


-- 7.14 How much can I allocate to savings each month based on trends?
SELECT 
    MONTH(TransDate) AS Month,
    SUM(AmountIn) AS TotalIncome,
    SUM(AmountOut) AS TotalSpent,
    SUM(AmountIn) - SUM(AmountOut) AS PotentialSavings
FROM Transactions
GROUP BY MONTH(TransDate)
ORDER BY Month;