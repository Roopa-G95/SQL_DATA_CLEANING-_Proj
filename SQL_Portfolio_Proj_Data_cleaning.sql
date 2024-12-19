-- Data Cleaning

SELECT * FROM layoffs;

-- CREATE ANOTHER BASE TABLE
I/*norder to create similar table we should have atleast 1 column so in such cases we will use the below code "LIKE" 
which will copy the table column */

CREATE TABLE layoffs_basedata
LIKE layoffs;
INSERT layoffs_basedata
SELECT * FROM layoffs;

SELECT * FROM layoffs_basedata;

-- REMOVE DUPLICATES
-- STANDARDIZE THE DATA
-- NULL VALUES OR BLANK VALUES
-- REMOVE ANY UNNECCESSARY COLUMNS

SELECT * FROM layoffs;
-- Below used to create unique row number
SELECT *,
ROW_NUMBER() OVER(PARTITION BY company,location,industry,total_laid_off,percentage_laid_off,'date',stage,country,funds_raised_millions) as row_num 
FROM layoffs;

-- to check for duplicate row_num
WITH duplicate_cte AS(
SELECT *,
ROW_NUMBER() OVER(PARTITION BY company,location,industry,total_laid_off,percentage_laid_off,'date',stage,country,funds_raised_millions) as row_num 
FROM layoffs)
SELECT * FROM duplicate_cte where row_num >1;

select * from layoffs where ï»¿company in ('casper');
ALTER TABLE layoffs RENAME COLUMN ï»¿company TO company; -- change column name

-- DELETE THE DUPLICATE
-- Tried this but error popped up -> here delete is not updatable
WITH duplicate_cte AS(
SELECT *,
ROW_NUMBER() OVER(PARTITION BY company,location,industry,total_laid_off,percentage_laid_off,'date',stage,country,funds_raised_millions) as row_num 
FROM layoffs)
DELETE FROM duplicate_cte where row_num >1;

-- creating another layoff table to copy the temp column row number
-- RIGHT CLICK LAYOFFS TABLE ->COPY TO CLIPBOARD -> CREATE STATEMENT to get below query
CREATE TABLE `layoffs2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT layoffs2 
SELECT *,
ROW_NUMBER() OVER(PARTITION BY company,location,industry,total_laid_off,percentage_laid_off,'date',stage,country,funds_raised_millions) as row_num 
FROM layoffs;
SELECT * FROM layoffs2
WHERE row_num>1;
DELETE FROM layoffs2
WHERE row_num>1;
SELECT * FROM layoffs2
WHERE row_num=1;

-- Standardizing data
-- Trimming the spaces
UPDATE layoffs2
SET company = TRIM(company);

UPDATE layoffs
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';
select distinct industry from layoffs2;

-- fix the . at the end of the country name
SELECT DISTINCT country, TRIM(TRAILING '.' FROM country) from layoffs2 order by 1; -- order by country asc
-- to change the date format
SELECT FORMAT(`date`, '%m/%d/%Y')
FROM layoffs2;
-- using case since 2 date formt is present
SELECT `date`,
CASE 
           WHEN `date` LIKE '%-%' THEN STR_TO_DATE(`date`, '%m-%d-%Y')  -- Handle date with dashes. original date formate is %Y-%m-%d
           WHEN `date` LIKE '%/%' THEN STR_TO_DATE(`date`, '%m/%d/%Y')  -- Handle date with slashes
           ELSE NULL  -- Handle cases where the date format is unknown or inconsistent
       END AS formatted_date
FROM layoffs2;

UPDATE layoffs2
SET `date` = CASE 
                WHEN `date` LIKE '%-%' THEN STR_TO_DATE(`date`, '%m-%d-%Y')
                WHEN `date` LIKE '%/%' THEN STR_TO_DATE(`date`, '%m/%d/%Y')
                ELSE null  -- Handle cases where the date format is unknown or inconsistent
             END;
-- Changing date format from text to date
ALTER TABLE layoffs2
MODIFY COLUMN `date` DATE;
SELECT * FROM layoffs2
;

-- to check the industry column for null self join used
SELECT * FROM layoffs2 t1
JOIN layoffs2 t2
ON t1.company = t2.company
AND t1.location = t2.location;

UPDATE layoffs2 SET industry = NULL WHERE industry = '';

/*This SQL query updates the industry column in the layoffs2 table by copying the value from another row within the same table 
where the company matches and the industry is already populated in that other row.*/

UPDATE layoffs2 t1
JOIN layoffs2 t2 on t1.company = t2.company
SET t1.industry = t2.industry
WHERE (t1.industry IS NULL OR t1.industry = '') AND t2.industry IS NOT NULL;

SELECT * FROM layoffs2 WHERE company = 'Airbnb';

-- DELETING DATA WHICH DOESNT ADD VALUE TO THE ANALYSIS
SELECT * FROM layoffs2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

DELETE FROM layoffs2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

-- FINALLY DELETING THE ROW NUMB

ALTER TABLE layoffs2
DROP COLUMN row_num;
SELECT * FROM layoffs2;
