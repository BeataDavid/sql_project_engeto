-- SELECT pro prvni tabulku
CREATE OR REPLACE TABLE t_beata_davidova_project_SQL_primary_final AS
SELECT a.payroll_year, a.odvetvi, a.prumerna_mzda, b.category_code, b.potravina, AVG(b.prumerna_cena1) AS prumerna_cena
	FROM (
	SELECT cp.payroll_year,  cpib.name AS odvetvi, avg(cp.value) as prumerna_mzda
	FROM czechia_payroll cp
	LEFT JOIN czechia_payroll_calculation cpc
		ON cp.calculation_code = cpc.code
	LEFT JOIN czechia_payroll_industry_branch cpib
		ON cp.industry_branch_code = cpib.code
	LEFT JOIN czechia_payroll_value_type cpvt
		ON cp.value_type_code = cpvt.code
	WHERE cpvt.code  =5958
		AND cpc.code = 200
	GROUP BY cp.payroll_year, cpib.name) a
	LEFT JOIN (
	SELECT cp.category_code, cpc.name AS potravina, cp.region_code, YEAR (cp.date_FROM) AS price_measured_year, avg(value) AS prumerna_cena1
	FROM czechia_price cp 
	JOIN czechia_price_category cpc 
		ON cpc.code = cp.category_code 
	GROUP BY cp.category_code, cp.region_code, YEAR (cp.date_FROM) ) b 
		ON a.payroll_year = b.price_measured_year
	WHERE a.payroll_year BETWEEN 2006 AND 2018
	GROUP BY odvetvi, payroll_year, category_code
;

-- SELECT pro druhou tabulku
CREATE OR REPLACE TABLE t_beata_davidova_project_SQL_secondary_final AS
SELECT c.country, year, GDP AS hdp, gini, c.population 
	FROM  economies e 
	join countries c on c.country  = e.country 
	WHERE year BETWEEN 2006 AND 2018
		and c.continent  = 'Europe'	;