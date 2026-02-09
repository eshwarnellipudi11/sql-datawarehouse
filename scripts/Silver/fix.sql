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
