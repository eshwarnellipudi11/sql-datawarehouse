INSERT INTO silver.crm_cust_info(
	cst_id,
	cst_key,
	cst_firstname,
	cst_lastname,
	cst_marital_status,
	cst_gndr,
	cst_create_date
)
Select cst_id, cst_key,
trim(cst_firstname) as cst_firstname,
trim(cst_lastname) as cst_lastname,
	CASE
	WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
	WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
	ELSE 'n/a'
	End As cst_maritial_status,
	CASE
	WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
	WHEN UPPER(TRIM(cst_gndr)) = 'M' THEn 'Male'
	ELSE 'n/a'
	END as cst_gndr,
cst_create_date
from
(Select *,
ROW_NUMBER() OVER(partition by cst_id Order by cst_create_date Desc) as cust_rank_by_date
from bronze.crm_cust_info) As t
Where cust_rank_by_date = 1 AND Cst_id IS NOT NULL;



-- Inserting the data in silver.crm_prd_info --


INSERT INTO silver.crm_prd_info(
	prd_id,
	cat_id,
	prd_key,
	prd_nm,
	prd_cost,
	prd_line,
	prd_start_dt,
	prd_end_dt
)
Select 
prd_id,
replace(substring(prd_key,1,5),'-', '_') AS cat_id,
substring(prd_key,7, len(prd_key)) As prd_key,
prd_nm,
ISNULL (prd_cost,0) As prd_cost,
  CASE
	WHEN UPPER(trim(prd_line)) = 'M' Then 'Mountain'
	WHEN UPPER(trim(prd_line)) = 'S' Then 'Other Size'
	WHEN UPPER(trim(prd_line)) = 'T' Then 'Touring'
	WHEN UPPER(trim(prd_line)) = 'R' Then 'Road'
else 'n/a'
End As prd_line,
CAST(prd_start_dt as date) As prd_start_dt,
CAST(lead(prd_start_dt) Over(partition by prd_key Order By prd_start_dt) - 1 as date) AS prd_end_dt
from bronze.crm_prd_info;
