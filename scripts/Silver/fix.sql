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

-- Inserting the data in silver.crm_sales_details --

INSERT INTO silver.crm_sales_details (
			sls_ord_num,
			sls_prd_key,
			sls_cust_id,
			sls_order_dt,
			sls_ship_dt,
			sls_due_dt,
			sls_sales,
			sls_quantity,
			sls_price
		)
		SELECT 
			sls_ord_num,
			sls_prd_key,
			sls_cust_id,
			CASE 
				WHEN sls_order_dt = 0 OR LEN(sls_order_dt) != 8 THEN NULL
				ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)
			END AS sls_order_dt,
			CASE 
				WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) != 8 THEN NULL
				ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE)
			END AS sls_ship_dt,
			CASE 
				WHEN sls_due_dt = 0 OR LEN(sls_due_dt) != 8 THEN NULL
				ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE)
			END AS sls_due_dt,
			CASE 
				WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != sls_quantity * ABS(sls_price) 
					THEN sls_quantity * ABS(sls_price)
				ELSE sls_sales
			END AS sls_sales,
			sls_quantity,
			CASE 
		WHEN sls_price IS NULL OR sls_price <= 0 
	THEN sls_sales / NULLIF(sls_quantity, 0)
	ELSE sls_price 
	END AS sls_price
FROM bronze.crm_sales_details;


-- Inserting the data in silver.erp_cust_az12 --

Insert Into silver.erp_cust_az12(
	cid,
	bdate,
	gen
)
Select
	CASE
	WHEN cid Like 'NAS%' THEN SUBSTRING(cid, 4,Len(cid)) 
	Else cid
	End As cid,
	CASE
	WHEN bdate > getdate() then NULL
	else bdate
	End As bdate,
	CASE
	When UPPER(TRIM(gen)) IN ('M', 'Male') THEN 'Male'
	When UPPER(TRIM(gen)) IN ('F', 'Female') THEN 'Female'
	Else 'n/a'
	End As gen
from bronze.erp_cust_az12;

-- Inserting the data in silver.erp_loc_a101 --

INSERT INTO silver.erp_loc_a101(
	cid,
	cntry
)
Select
replace(cid, '-', '') As Cid,
CASE
WHEN TRIM(cntry) IN ('DE', 'Germany') THEN 'Germany'
WHEN TRIM(cntry) IN ('US','USA', 'United states') THEN 'United States'
WHEN TRIM(cntry) = '' OR cntry IS NULL then 'n/a'
Else TRIM('n/a')
End As cntry
From bronze.erp_loc_a101;


-- Inserting the data in silver.erp_px_cat_g1v2 --

INSERT INTO silver.erp_px_cat_g1v2(
	id,
	cat,
	subcat,
	maintenance
) 
SELECT * FROM bronze.erp_px_cat_g1v2;
