--1. Purchased products (purchase count and quantity purchased) per month
--Aggregates for all products by month/year
SELECT
	YEAR(tCPH.PurchaseDate) AS PurchaseYear
	, MONTH(tCPH.PurchaseDate) AS PurchaseMonth
	--, tP.ProductName
	, COUNT(tCPH.ProductID) AS PurchaseCount
	, SUM(tCPH.Quantity) aS QuantityPurchased
FROM dbo.CustomerPurchaseHistory tCPH
LEFT JOIN dbo.Product tP ON tP.ProductID = tCPH.ProductID
GROUP BY
	YEAR(tCPH.PurchaseDate) 
	, MONTH(tCPH.PurchaseDate)
	--, tP.ProductName
ORDER BY 
	MONTH(tCPH.PurchaseDate) ASC
	, YEAR(tCPH.PurchaseDate) DESC

--Aggregates for all products by product/month/year 
SELECT
	YEAR(tCPH.PurchaseDate) AS PurchaseYear
	, MONTH(tCPH.PurchaseDate) AS PurchaseMonth
	, tP.ProductName
	, COUNT(tCPH.ProductID) AS PurchaseCount
	, SUM(tCPH.Quantity) aS QuantityPurchased
FROM dbo.CustomerPurchaseHistory tCPH
LEFT JOIN dbo.Product tP ON tP.ProductID = tCPH.ProductID
GROUP BY
	YEAR(tCPH.PurchaseDate) 
	, MONTH(tCPH.PurchaseDate)
	, tP.ProductName
ORDER BY 
	tP.ProductName ASC
	, MONTH(tCPH.PurchaseDate) ASC
	, YEAR(tCPH.PurchaseDate) DESC
	 

--2. Average age of customer per product sold
SELECT
tP.ProductName
--If there is a need for a specific precicion for age, can convert to numeric or decimal 
, ROUND(AVG(CONVERT(FLOAT, tCD.Age)), 2) AS AverageAge
FROM dbo.CustomerPurchaseHistory tCPH
LEFT JOIN dbo.CustomerDemographics tCD ON tCD.CustomerID = tCPH.Customer
LEFT JOIN dbo.Product tP ON tP.ProductID = tCPH.ProductID
GROUP BY tP.ProductName

--3. Which products are purchased most by age group (18-28, 29-38, etc.)

;WITH CTE_ageGroup AS (
SELECT
*
--Can change age grouping as needed
, CASE 
	WHEN Age < 18
	THEN NULL
	WHEN Age >= 18 AND Age <= 28
	THEN 1
	WHEN Age >= 29 AND Age <= 38
	THEN 2
	WHEN Age >= 39 AND Age <= 48
	THEN 3
	WHEN Age >= 49 AND Age <= 58
	THEN 4
	WHEN Age >= 59 AND Age <= 68
	THEN 5
	WHEN Age >= 69 AND Age <= 78
	THEN 6
	WHEN Age >= 79 AND Age <= 88
	THEN 7
	WHEN Age >= 89 AND Age <= 100
	THEN 9
	ELSE NULL
END AS AgeGroup
FROM dbo.CustomerDemographics
), CTE_RANK AS (
SELECT
AgeGroup
, tCPH.ProductID
, COUNT(tCPH.ProductID) AS PurchaseCount
--Using Rank because I wanted to grab ties in Purchase counts. If ties are not needed, can use ROW_NUMBER instead
, RANK() OVER(PARTITION BY AgeGroup ORDER BY COUNT(tCPH.ProductID) DESC) AS RANKAgeGroup
FROM dbo.CustomerPurchaseHistory tCPH
LEFT JOIN dbo.Product tP ON tP.ProductID = tCPH.ProductID
LEFT JOIN CTE_ageGroup ON CTE_ageGroup.CustomerID = tCPH.Customer
GROUP BY
	AgeGroup
	, tCPH.ProductID
)
SELECT
AgeGroup
, ProductID
, PurchaseCount
FROM CTE_RANK
WHERE RANKAgeGroup = 1

--This query has the ranking partitioned by ProductID instead of AgeGroup in case I misunderstood the question.
;WITH CTE_ageGroup AS (
SELECT
*
--Can change age grouping as needed
, CASE 
	WHEN Age < 18
	THEN NULL
	WHEN Age >= 18 AND Age <= 28
	THEN 1
	WHEN Age >= 29 AND Age <= 38
	THEN 2
	WHEN Age >= 39 AND Age <= 48
	THEN 3
	WHEN Age >= 49 AND Age <= 58
	THEN 4
	WHEN Age >= 59 AND Age <= 68
	THEN 5
	WHEN Age >= 69 AND Age <= 78
	THEN 6
	WHEN Age >= 79 AND Age <= 88
	THEN 7
	WHEN Age >= 89 AND Age <= 100
	THEN 9
	ELSE NULL
END AS AgeGroup
FROM dbo.CustomerDemographics
), CTE_RANK AS (
SELECT
tCPH.ProductID
, AgeGroup
, COUNT(tCPH.ProductID) AS PurchaseCount
--Using Rank because I wanted to grab ties in Purchase counts. If ties are not needed, can use ROW_NUMBER instead
, RANK() OVER(PARTITION BY tCPH.ProductID ORDER BY COUNT(tCPH.ProductID) DESC) AS RANKAgeGroup
FROM dbo.CustomerPurchaseHistory tCPH
LEFT JOIN dbo.Product tP ON tP.ProductID = tCPH.ProductID
LEFT JOIN CTE_ageGroup ON CTE_ageGroup.CustomerID = tCPH.Customer
GROUP BY
	AgeGroup
	, tCPH.ProductID
)
SELECT
ProductID
, AgeGroup
, PurchaseCount
FROM CTE_RANK
WHERE RANKAgeGroup = 1

--4. Repeat customers
SELECT
Customer
, COUNT(Customer) AS RepeatCustomerCount
FROM dbo.CustomerPurchaseHistory
GROUP BY 
	Customer
HAVING COUNT(Customer) > 1
ORDER BY Customer ASC

--5. Based on the dataset, provide any other metrics that could be useful to the business.
--Amount of days between purchases
--Also checks to see if the product purchased is a repeat product purchased
--Then finds how much was bought the last time this product was purchased and finds the numerical difference.
;WITH CTE_PrevPurchaseDate AS (
SELECT
Customer
, ProductID
, PurchaseDate
, Quantity
, LAG(PurchaseDate, 1, NULL) RESPECT NULLS OVER (PARTITION BY Customer ORDER BY PurchaseDate ASC) AS PreviousPurchaseDate
, LAG(ProductID, 1, NULL) RESPECT NULLS OVER (PARTITION BY Customer, ProductID ORDER BY PurchaseDate ASC) AS RepeatProductPurchase
, LAG(Quantity, 1, NULL) RESPECT NULLS OVER (PARTITION BY Customer, ProductID ORDER BY PurchaseDate ASC) AS PrevRepeatQuantity
FROM dbo.CustomerPurchaseHistory
)
SELECT
Customer
, ProductID
, PurchaseDate
, Quantity
, DATEDIFF(DAY, PreviousPurchaseDate, PurchaseDate)  AS DaysFromPreviousPurchase
, CASE 
	WHEN RepeatProductPurchase IS NOT NULL
	THEN 1
	ELSE 0
END AS RepeatProductPurchase
, PrevRepeatQuantity
, (Quantity - PrevRepeatQuantity) AS DiffRepeatQuantity
FROM CTE_PrevPurchaseDate


