#Exploring the dataset

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

#SQL Queries and Outputs

-- 1.Fetch all the paintings which are not displayed in any museums

SELECT * FROM work
WHERE museum_id IS NULL;  

-- 2.Are there museuems without any paintings

SELECT M.*
FROM MUSEUM AS M
LEFT JOIN WORK AS W
ON M.MUSEUM_ID= W.MUSEUM_ID
WHERE M.MUSEUM_ID IS NULL;  -- Output -- There is no museuems without any painting

-- 3.How many paintings have an asking price of more than their regular price?

SELECT * FROM product_size
WHERE sale_price > regular_price; -- Output -- There is no paintings have an asking price of more than their regular price.

-- 4.Identify the paintings whose asking price is less than 50% of its regular price

SELECT COUNT(*) FROM product_size
WHERE sale_price < 0.5 * regular_price; --  Output -- There are 52 paintings whose asking price is less than 50% of its regular price.
-- OR
SELECT * 
FROM product_size
WHERE sale_price < regular_price / 2; 

-- 5. Which canva size costs the most?
SELECT * 
FROM product_size 
ORDER BY sale_price DESC LIMIT  1; --  '4896' - SIZE ID, '1115'- PRICE

SELECT CS.label as Canva_Size, PS.sale_price as Cost
FROM product_size AS PS
LEFT JOIN canvas_size AS CS
ON PS.size_id= CS.size_id
ORDER BY 2 DESC
LIMIT 1;  -- Canva_Size: '48\" x 96\"(122 cm x 244 cm)', Cost: '1115'

-- Delete duplicate records from work, product_size, subject and image_link tables
-- WORK
DELETE FROM WORK 
WHERE WORK_ID IN (
	SELECT WORK_ID
	FROM
		(SELECT 
            WORK_ID, 
            ROW_NUMBER() OVER (PARTITION BY WORK_ID) AS RowNum
        FROM 
            WORK) AS sq
            WHERE RowNum > 1
            );
            
-- PRODUCT_SIZE
DELETE FROM product_size
WHERE WORK_ID IN (
	SELECT WORK_ID
	FROM
		(SELECT 
            WORK_ID, 
            ROW_NUMBER() OVER (PARTITION BY WORK_ID) AS RowNum
        FROM 
            WORK) AS sq
            WHERE RowNum > 1
            );
-- subject

DELETE FROM SUBJECT
WHERE WORK_ID IN (
	SELECT WORK_ID
	FROM
		(SELECT 
            WORK_ID, 
            ROW_NUMBER() OVER (PARTITION BY WORK_ID) AS RowNum
        FROM 
            WORK) AS sq
            WHERE RowNum > 1
            );
            
-- IMAGE_LINK
DELETE FROM IMAGE_LINK 
	WHERE WORK_ID IN ( 
		SELECT WORK_ID FROM(
	SELECT 
		WORK_ID,
        ROW_NUMBER() OVER (PARTITION BY WORK_ID) AS RowNum
	FROM IMAGE_LINK) As sq
 WHERE RowNum>1); -- All duplicate recrod deleted from selected Table.
 
 -- 7.Identify the museums with invalid city information in the given dataset
 
SELECT *
FROM museum
WHERE city IS NULL
   OR city REGEXP '^[0-9]'
   OR LENGTH(city) > 50
   OR city IN ('N/A', 'Unknown', 'XXXXX'); -- '6' MUSEUMS

-- 8. Fetch the top 10 most famous painting subject

SELECT COUNT(DISTINCT SUBJECT) FROM SUBJECT; -- 86 SUBJECT

SELECT  COUNT(*) WORK_ID, SUBJECT
FROM SUBJECT GROUP BY SUBJECT 
ORDER BY 1 DESC LIMIT 10;

SELECT s.subject, COUNT(*) AS no_of_paintings
FROM work w
JOIN subject s ON s.work_id = w.work_id
GROUP BY s.subject
ORDER BY COUNT(*) DESC
LIMIT 10;

-- 9.Identify the museums which are open on both Sunday and Monday. Display museum name, city.

SELECT DISTINCT m.NAME, m.city
FROM museum AS m
LEFT JOIN museum_hours as mh 
on m.museum_id=mh.museum_id
WHERE DAY IN ( 'SUNDAY','MONDAY');


-- 10.How many museums are open every single day

select 
 count(*)
from(
SELECT 
        museum_id, COUNT(*) AS no_of_museum_opening
    FROM
        museum_hours
    GROUP BY museum_id
   having no_of_museum_opening=7)x ;
   
-- 11. Which are the top 5 most popular museum? (Popularity is defined based on most no of paintings in a museum

SELECT M.NAME ,COUNT(W.WORK_ID) AS PAINTINGS
FROM MUSEUM AS M
LEFT JOIN WORK AS W
 ON M.MUSEUM_ID= W.MUSEUM_ID
 GROUP BY M.NAME
 ORDER BY 2 DESC 
 LIMIT 5;
 
 -- 12.Who are the top 5 most popular artist? (Popularity is defined based on most no of paintings done by an artist
 
 SELECT A.ARTIST_ID,A.FULL_NAME, COUNT(W.WORK_ID) AS WORKS
 FROM WORK AS W
 LEFT JOIN ARTIST AS A
 ON W.ARTIST_ID= A.ARTIST_ID
 GROUP BY 1,2
 ORDER BY WORKS DESC
 LIMIT 5;
 
 -- 13. Display the 3 least popular canva sizes
 SELECT 
  PS.SIZE_ID, CS.LABEL,
    COUNT(W.WORK_ID) AS WORKS
FROM
    WORK AS W
        LEFT JOIN
    PRODUCT_SIZE AS PS ON W.WORK_ID = PS.WORK_ID
        LEFT JOIN
    CANVAS_SIZE AS CS ON PS.SIZE_ID = CS.SIZE_ID
 GROUP BY 1 , 2
ORDER BY WORKS LIMIT 3;

SELECT
p.size_id, 
c.label,
count(w.work_id) as work_shown
FROM work w
JOIN product_size p
ON w.work_id = p.work_id
JOIN canvas_size c
ON c.size_id = p.size_id
group by 1,2
order by work_shown
limit 3;  

-- 14.Which museum is open for the longest during a day. Dispay museum name, state and hours open and which day?

SELECT M.MUSEUM_ID, M.NAME,
MAX(HOUR(timediff(
STR_TO_DATE(OPEN, '%h:%i:%p'),
STR_TO_DATE(CLOSE, '%h:%i:%p')
)))AS HOUR_GAP
FROM MUSEUM_HOURS AS MH
LEFT JOIN MUSEUM AS M ON
MH.MUSEUM_ID=M.MUSEUM_ID
GROUP BY 1,2 
ORDER BY HOUR_GAP DESC
LIMIT 1;

-- 15.Which museum has the most no of most popular painting style?

SELECT 
    COUNT(W.WORK_ID) AS WORKS, M.NAME, W.STYLE
FROM
    WORK AS W
        LEFT JOIN
    MUSEUM AS M ON W.MUSEUM_ID = M.MUSEUM_ID
GROUP BY 2,3
ORDER BY WORKS DESC
 LIMIT 1;

-- 16.Identify the artists whose paintings are displayed in multiple countries

SELECT DISTINCT 
       a.full_name AS artist,
       count(m.country) as Nc
    FROM 
        work w
    JOIN 
        artist a ON a.artist_id = w.artist_id
    JOIN 
        museum m ON m.museum_id = w.museum_id
group by 1
having Nc>1
order by 2 desc;


create table  temp2 (
 SELECT DISTINCT 
        a.full_name AS artist,
        m.country
    FROM 
        work w
    JOIN 
        artist a ON a.artist_id = w.artist_id
    JOIN 
        museum m ON m.museum_id = w.museum_id
);
select 
artist,
count(country) as country
from temp
group by artist
having country > 1
order by country desc;


-- 17.Display the country and the city with most no of museums. Output 2 seperate columns to mention the city and country. 
-- If there are multiple value, seperate them with comma.--
with CTE_Country as(
SELECT 
        country,
        COUNT(*) AS country_count,
        RANK() OVER (ORDER BY COUNT(1) DESC) AS country_rank
    FROM 
        museum
    GROUP BY 
        country 
        ),
  CTE_City as (SELECT 
        city,
        COUNT(1) AS city_count,
        RANK() OVER (ORDER BY COUNT(1) DESC) AS city_rank
    FROM 
        museum
    GROUP BY 
        city
        )
	SELECT 
    (SELECT GROUP_CONCAT(DISTINCT COUNTRY) FROM CTE_Country WHERE COUNTRY_RANK=1) AS TOP_COUNTRY,
    (SELECT GROUP_CONCAT(DISTINCT CITY) FROM CTE_City WHERE CITY_RANK=1) AS TOP_CITY;
    
    -- OUTPUT: 'USA', 'London,New York,Paris,Washington'
-- 18.Identify the artist and the museum where the most expensive and least expensive painting is placed. 
   -- Display the artist name, sale_price, painting name, museum name, museum city and canvas label
#MOST expensive painting 
   SELECT A.FULL_NAME AS ARTIST_NAME, PS.SALE_PRICE,W.NAME AS PAINTING_NAME ,M.NAME AS MUSEUM_NAME ,M.CITY AS MUSEUM_CITY,CS.LABEL AS CANVAS_LABEL
   FROM WORK AS W
   LEFT JOIN MUSEUM AS M
   ON M.MUSEUM_ID= W.MUSEUM_ID
   LEFT JOIN ARTIST AS A ON
   A.ARTIST_ID=W.ARTIST_ID
   LEFT JOIN PRODUCT_SIZE AS PS ON
   W.WORK_ID=PS.WORK_ID
   LEFT JOIN CANVAS_SIZE AS CS ON 
   PS.SIZE_ID=CS.SIZE_ID
   ORDER BY PS.SALE_PRICE DESC LIMIT 1;
#LEAST expensive painting 
   SELECT A.FULL_NAME AS ARTIST_NAME,PS.SALE_PRICE,W.NAME AS PAINTING_NAME ,M.NAME AS MUSEUM_NAME ,M.CITY AS MUSEUM_CITY,CS.LABEL AS CANVAS_LABEL
   FROM WORK AS W
   LEFT JOIN MUSEUM AS M
   ON M.MUSEUM_ID= W.MUSEUM_ID
   LEFT JOIN ARTIST AS A ON
   A.ARTIST_ID=W.ARTIST_ID
   LEFT JOIN PRODUCT_SIZE AS PS ON
   W.WORK_ID=PS.WORK_ID
   LEFT JOIN CANVAS_SIZE AS CS ON 
   PS.SIZE_ID=CS.SIZE_ID
   WHERE SALE_PRICE IS NOT NULL
   ORDER BY PS.SALE_PRICE ASC LIMIT 1;
   
 -- USING CTE
WITH cte AS (
    SELECT 
        w.work_id,
        full_name,
        sale_price,
        w.name AS museum_name,
        m.name,
        m.city,
        c.label,
        MAX(sale_price) OVER () AS max_sale_price,
        MIN(sale_price) OVER () AS min_sale_price
    FROM 
        product_size p 
    JOIN 
        work w ON w.work_id = p.work_id
    JOIN 
        museum m ON m.museum_id = w.museum_id
    JOIN 
        artist a ON a.artist_id = w.artist_id
    JOIN 
        canvas_size c ON c.size_id = p.size_id
)
SELECT 
    *
FROM 
    cte
WHERE 
    sale_price IN (max_sale_price, min_sale_price)
limit 2;


-- 19.Which country has the 5th highest no of paintings?

CREATE TEMPORARY TABLE temp AS
SELECT DISTINCT 
    a.full_name AS artist,
    m.country
FROM 
    work w
JOIN 
    artist a ON a.artist_id = w.artist_id
JOIN 
    museum m ON m.museum_id = w.museum_id;
 
SELECT COUNTRY,PAINTINGS
FROM
 (SELECT
	COUNTRY, 
    COUNT(*) AS PAINTINGS ,
    RANK() OVER (ORDER BY COUNT(*) DESC) AS RNK
    FROM temp
	GROUP BY COUNTRY
    ORDER BY RNK )X 
    WHERE RNK=5;

-- 20. Which are the 3 most popular and 3 least popular painting styles?

SELECT style,rnk,
 case 
  when rnk<=3 then 'most_popular'
  when rnk>=21 then 'least popular'
  else 'Mid popular'
  end as Popularity
  from(
select style,
count(*) AS TOTAL,
rank() OVER (ORDER BY COUNT(*)) AS RNK from work group by 1)C ;

-- alt 
SELECT 
    style,
    CASE 
        WHEN rnk <= 3 THEN 'Most Popular'
        ELSE 'Least Popular' 
    END AS popularity
FROM (
    SELECT 
        style,
        RANK() OVER (ORDER BY cnt DESC) AS rnk
    FROM (
        SELECT 
            style,
            COUNT(*) AS cnt
        FROM 
            work
        WHERE 
            style IS NOT NULL
        GROUP BY 
            style
    ) AS subquery
) AS ranked_styles
WHERE 
    rnk <= 3
    OR rnk > (SELECT COUNT(DISTINCT style) FROM work WHERE style IS NOT NULL) - 3;
    
-- 21.Which artist has the most no of Portraits paintings outside USA?. Display artist name, no of paintings and the artist nationality.
 SELECT 
    full_name AS Artist_Name,
    nationality,
    no_of_paintings
FROM (
    SELECT 
        a.full_name,
        a.nationality,
        COUNT(*) AS no_of_paintings,
        RANK() OVER (ORDER BY COUNT(*) DESC) AS rnk
    FROM 
        work w
    JOIN 
        artist a ON a.artist_id = w.artist_id
    JOIN 
        subject s ON s.work_id = w.work_id
    JOIN 
        museum m ON m.museum_id = w.museum_id
    WHERE 
        s.subject = 'Portraits'
        AND m.country != 'USA'
    GROUP BY 
        a.full_name, a.nationality
) x
WHERE 
    rnk = 1;