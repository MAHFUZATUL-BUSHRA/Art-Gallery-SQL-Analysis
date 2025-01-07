# Art-Gallery-SQL-Analysis
This project is focused on analyzing a comprehensive database from an art gallery, containing information about artists, artworks, museums, canvas sizes, and more. The goal is to extract actionable insights, clean and preprocess the data, and answer key business questions using SQL.
This project involves exploring and analyzing a comprehensive database of an art gallery. The database includes tables such as artist, canvas_size, image_link, museum, museum_hours, subject, work, and product_size. The main goal is to extract meaningful insights and perform data cleaning using SQL queries.

## Key objectives include:

    - Identifying artworks not displayed in museums.
    - Analyzing museum operations and painting details.
    - Cleaning duplicate records in key tables.
    - Investigating museum and artwork metadata.
    - Extracting business-relevant insights, such as the most popular painting styles and artists.


## Dataset Overview
 ### Tables and Row Counts:
     * artist: 421 rows
     * canvas_size: 200 rows
     * image_link: 14,775 rows
     * museum: 57 rows
     * museum_hours: 351 rows
     * subject: 6,284 rows
     * work: 2,646 rows
     * product_size: 106,629 rows

  ### Exploring the dataset
```sql
SELECT * FROM artist; 
SELECT COUNT(*) FROM artist;  -- '421'
SELECT * FROM canvas_size;
SELECT COUNT(*) FROM canvas_size;  -- 200
SELECT * FROM image_link;
SELECT COUNT(*) FROM image_link; -- '14775'
SELECT * FROM museum;
SELECT COUNT(*) FROM museum; -- '57'
SELECT * FROM museum_hours;
SELECT COUNT(*) FROM museum_hours; -- '351'
SELECT * FROM  subject;
SELECT COUNT(*) FROM  subject; -- '6284'
SELECT * FROM work;
SELECT COUNT(*) FROM work; -- '2646'
SELECT * FROM product_size;
SELECT COUNT(*) FROM product_size; -- '106629'
```
# SQL Queries and Outputs

### 1. Fetch all the paintings which are not displayed in any museums
```sql
SELECT * FROM work
WHERE museum_id IS NULL;  
```
### 2. Are there museums without any paintings?
```sql
SELECT M.*
FROM museum AS M
LEFT JOIN work AS W
ON M.museum_id = W.museum_id
WHERE W.museum_id IS NULL;  
```
### 3. How many paintings have an asking price of more than their regular price?
```sql
SELECT * FROM product_size
WHERE sale_price > regular_price;  
```
### 4. Identify the paintings whose asking price is less than 50% of its regular price
```sql
SELECT COUNT(*) FROM product_size
WHERE sale_price < 0.5 * regular_price; 
```
### 5. Which canvas size costs the most?
```sql
SELECT CS.label AS Canvas_Size, PS.sale_price AS Cost
FROM product_size AS PS
LEFT JOIN canvas_size AS CS
ON PS.size_id = CS.size_id
ORDER BY 2 DESC
LIMIT 1;  
```
### 6. Delete duplicate records from work, product_size, subject, and image_link tables
```sql
DELETE FROM work 
WHERE work_id IN (
	SELECT work_id
	FROM (
		SELECT work_id, ROW_NUMBER() OVER (PARTITION BY work_id) AS RowNum
		FROM work) AS sq
	WHERE RowNum > 1
);

DELETE FROM product_size
WHERE work_id IN (
	SELECT work_id
	FROM (
		SELECT work_id, ROW_NUMBER() OVER (PARTITION BY work_id) AS RowNum
		FROM work) AS sq
	WHERE RowNum > 1
);

DELETE FROM subject
WHERE work_id IN (
	SELECT work_id
	FROM (
		SELECT work_id, ROW_NUMBER() OVER (PARTITION BY work_id) AS RowNum
		FROM work) AS sq
	WHERE RowNum > 1
);

DELETE FROM image_link 
WHERE work_id IN (
	SELECT work_id 
	FROM (
		SELECT work_id, ROW_NUMBER() OVER (PARTITION BY work_id) AS RowNum
		FROM image_link) AS sq
	WHERE RowNum > 1
);
```

### 7. Identify museums with invalid city information
```sql
SELECT *
FROM museum
WHERE city IS NULL
   OR city REGEXP '^[0-9]'
   OR LENGTH(city) > 50
   OR city IN ('N/A', 'Unknown', 'XXXXX');  
```
### 8. Fetch the top 10 most famous painting subjects
```sql
SELECT s.subject, COUNT(*) AS no_of_paintings
FROM work w
JOIN subject s ON s.work_id = w.work_id
GROUP BY s.subject
ORDER BY COUNT(*) DESC
LIMIT 10;
```
### 9. Identify museums open on both Sunday and Monday. Display museum name, city.
```sql
SELECT DISTINCT m.name, m.city
FROM museum AS m
LEFT JOIN museum_hours AS mh 
ON m.museum_id = mh.museum_id
WHERE day IN ('SUNDAY', 'MONDAY');
```
### 10. How many museums are open every single day?
```sql
SELECT COUNT(*)
FROM (
	SELECT museum_id, COUNT(*) AS no_of_open_days
	FROM museum_hours
	GROUP BY museum_id
	HAVING no_of_open_days = 7
) x;
```
### 11. Top 5 most popular museums based on paintings
```sql
SELECT M.name, COUNT(W.work_id) AS paintings
FROM museum AS M
LEFT JOIN work AS W
ON M.museum_id = W.museum_id
GROUP BY M.name
ORDER BY 2 DESC
LIMIT 5;
```
### 12. Top 5 most popular artists
```sql
SELECT A.artist_id, A.full_name, COUNT(W.work_id) AS works
FROM work AS W
LEFT JOIN artist AS A
ON W.artist_id = A.artist_id
GROUP BY 1, 2
ORDER BY works DESC
LIMIT 5;
```
### 13. Display the 3 least popular canvas sizes
```sql
SELECT 
  PS.size_id, CS.label, COUNT(W.work_id) AS works
FROM work AS W
LEFT JOIN product_size AS PS ON W.work_id = PS.work_id
LEFT JOIN canvas_size AS CS ON PS.size_id = CS.size_id
GROUP BY 1, 2
ORDER BY works 
LIMIT 3;
```
### 14. Which museum is open the longest during a day?
```sql
SELECT M.museum_id, M.name,
MAX(HOUR(TIMEDIFF(
STR_TO_DATE(open, '%h:%i:%p'),
STR_TO_DATE(close, '%h:%i:%p')
))) AS hour_gap
FROM museum_hours AS MH
LEFT JOIN museum AS M ON MH.museum_id = M.museum_id
GROUP BY 1, 2
ORDER BY hour_gap DESC
LIMIT 1;
```
### 15. Museum with the most popular painting style
```sql
SELECT 
    COUNT(W.work_id) AS works, M.name, W.style
FROM work AS W
LEFT JOIN museum AS M ON W.museum_id = M.museum_id
GROUP BY 2, 3
ORDER BY works DESC
LIMIT 1;
```
### 16. Artists with paintings displayed in multiple countries
```sql
SELECT DISTINCT a.full_name AS artist, COUNT(m.country) AS Nc
FROM work W
JOIN artist A ON A.artist_id = W.artist_id
JOIN museum M ON M.museum_id = W.museum_id
GROUP BY 1
HAVING Nc > 1
ORDER BY 2 DESC;
```
### 17. Country and city with the most museums
```sql
WITH CTE_Country AS (
SELECT country, COUNT(*) AS country_count, RANK() OVER (ORDER BY COUNT(1) DESC) AS country_rank
FROM museum
GROUP BY country),
CTE_City AS (
SELECT city, COUNT(1) AS city_count, RANK() OVER (ORDER BY COUNT(1) DESC) AS city_rank
FROM museum
GROUP BY city)
SELECT 
(SELECT GROUP_CONCAT(DISTINCT country) FROM CTE_Country WHERE country_rank = 1) AS top_country,
(SELECT GROUP_CONCAT(DISTINCT city) FROM CTE_City WHERE city_rank = 1) AS top_city;
```
### 18. Most and least expensive painting details
```sql
WITH cte AS (
    SELECT 
        w.work_id, full_name, sale_price, w.name AS museum_name,
        m.name, m.city, c.label,
        MAX(sale_price) OVER () AS max_sale_price,
        MIN(sale_price) OVER () AS min_sale_price
    FROM product_size P
    JOIN work W ON W.work_id = P.work_id
    JOIN museum M ON M.museum_id = W.museum_id
    JOIN artist A ON A.artist_id = W.artist_id
    JOIN canvas_size C ON C.size_id = P.size_id
)
SELECT *
FROM cte
WHERE sale_price IN (max_sale_price, min_sale_price)
LIMIT 2;
```
### 19. Country with the 5th highest number of paintings
```sql
CREATE TEMPORARY TABLE temp AS
SELECT DISTINCT a.full_name AS artist, m.country
FROM work W
JOIN artist A ON A.artist_id = W.artist_id
JOIN museum M ON M.museum_id = W.museum_id;
 
SELECT country, paintings
FROM (
	SELECT country, COUNT(*) AS paintings, RANK() OVER (ORDER BY COUNT(*) DESC) AS rnk
	FROM temp
	GROUP BY country
	ORDER BY rnk) x
WHERE rnk = 5;
```
### 20. Top 3 and bottom 3 painting styles
```sql
SELECT 
    style,
    CASE 
        WHEN rnk <= 3 THEN 'Most Popular'
        WHEN rnk >= (SELECT COUNT(DISTINCT style) FROM work WHERE style IS NOT NULL) - 3 THEN 'Least Popular'
        ELSE 'Mid Popular'
    END AS popularity
FROM (
    SELECT style, COUNT(*) AS total, RANK() OVER (ORDER BY COUNT(*) DESC) AS rnk
    FROM work
    WHERE style IS NOT NULL
    GROUP BY style
) C;
```
### 21. Most portrait paintings outside the USA
```sql
SELECT full_name AS artist_name, nationality, no_of_paintings
FROM (
    SELECT A.full_name, A.nationality, COUNT(*) AS no_of_paintings, 
    RANK() OVER (ORDER BY COUNT(*) DESC) AS rnk
    FROM work W
    JOIN artist A ON A.artist_id = W.artist_id
    JOIN subject S ON S.work_id = W.work_id
    JOIN museum M ON M.museum_id = W.museum_id
    WHERE S.subject = 'Portraits' AND M.country != 'USA'
    GROUP BY A.full_name, A.nationality
) X
WHERE rnk = 1;
```
