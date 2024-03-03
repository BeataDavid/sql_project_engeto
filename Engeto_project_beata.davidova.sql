-- SELECT pro prvni tabulku

CREATE OR REPLACE TABLE t_beata_davidova_project_SQL_primary_final AS
SELECT a.payroll_year, a.odvetvi, a.prumerna_mzda, b.category_code, b.prumerna_cena
	FROM (
	SELECT cp.payroll_year,  cpib.name as odvetvi, avg(cp.value) as prumerna_mzda
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
	SELECT cp.category_code, cp.region_code, date_format(cp.date_FROM, '%Y') AS price_measured_year, avg(value) AS prumerna_cena
	FROM czechia_price cp 
	JOIN czechia_price_category cpc 
		ON cpc.code = cp.category_code 
	GROUP BY cp.category_code, cp.region_code, date_format(cp.date_FROM, '%Y') ) b 
		ON a.payroll_year = b.price_measured_year
	;

-- 1. Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých klesají? 
-- Ne, nerotla vždy. Mzda klesla v těchto odvětvích v těchto letech.

SELECT res.payroll_year, res.odvetvi, res.rozdil 
FROM (
	SELECT act.payroll_year, act.odvetvi, act.prumerna_mzda - prev.prumerna_mzda AS rozdil
	FROM (
		SELECT a.payroll_year, a.odvetvi, AVG(a.prumerna_mzda) AS prumerna_mzda
		FROM t_beata_davidova_project_SQL_primary_final a
		GROUP BY a.payroll_year, a.odvetvi ) act
	LEFT JOIN (
	    SELECT b.payroll_year, b.odvetvi, AVG(b.prumerna_mzda) AS prumerna_mzda
		FROM t_beata_davidova_project_SQL_primary_final b
		GROUP BY b.payroll_year, b.odvetvi ) prev ON act.payroll_year = prev.payroll_year+1 
		      AND act.odvetvi = prev.odvetvi
) res
	WHERE res.rozdil < 0
	;

-- 2. Kolik je možné si koupit litrů mléka a kilogramů chleba za první a poslední srovnatelné období v dostupných datech cen a mezd?
-- Hledání kódu chleba a mléka
SELECT *
	FROM czechia_price_category cpc
	WHERE name LIKE "Chléb%" OR name LIKE "Mléko%"
	;
-- SELECT na Chleba - V roce 2006 bylo možné za průměrnou mzdu napříč odvětvími nakoupit 1 307 kilogramů chleba. V roce 2018 to bylo 1 363 kg.
SELECT payroll_year, AVG(prumerna_mzda) AS prumerna_mzda_all, category_code, AVG(prumerna_cena) AS prumerna_cena_all, AVG(prumerna_mzda) / AVG(prumerna_cena) as kolik_lze_nakoupit
		FROM t_beata_davidova_project_SQL_primary_final
		WHERE category_code = "111301" AND (payroll_year = "2006" OR payroll_year = "2018")
		GROUP BY payroll_year
		;
-- SELECT na Mléko - V roce 2006 bylo možné za průměrnou mzdu napříč odvětvími nakoupit 1 460 litrů mléka. V roce 2018 to bylo 1 667 litrů.		
SELECT payroll_year, AVG(prumerna_mzda) AS prumerna_mzda_all, category_code, AVG(prumerna_cena) AS prumerna_cena_all, AVG(prumerna_mzda) / AVG(prumerna_cena) as kolik_lze_nakoupit
		FROM t_beata_davidova_project_SQL_primary_final
		WHERE category_code = "114201" AND (payroll_year = "2006" OR payroll_year = "2018")
		GROUP BY payroll_year
		; 

-- 3. Která kategorie potravin zdražuje nejpomaleji (je u ní nejnižší percentuální meziroční nárůst)
-- Nejpomaleji zdražovalo v mezi lety 2006 a 2018 máslo.

SELECT act.category_code, (act.prumerna_cena/prev.prumerna_cena)/(2018 - 2006 + 1) * 100 AS rocni_narust
	FROM (
		SELECT a.payroll_year, a.category_code, AVG(a.prumerna_cena) AS prumerna_cena
		FROM t_beata_davidova_project_SQL_primary_final a
		WHERE a.payroll_year = "2006"
		GROUP BY a.payroll_year, a.category_code ) act
	LEFT JOIN (
	    SELECT b.payroll_year, b.category_code, AVG(b.prumerna_cena) AS prumerna_cena
		FROM t_beata_davidova_project_SQL_primary_final b
		WHERE b.payroll_year = "2018"
		GROUP BY b.payroll_year, b.category_code ) prev ON act.category_code = prev.category_code
	ORDER BY rocni_narust 
	;

-- Hledání názvu odpovědi.
SELECT *
	FROM czechia_price_category cpc 
	WHERE code = "115101"
	;

-- 4. Existuje rok, ve kterém byl meziroční nárůst cen potravin výrazně vyšší než růst mezd (větší než 10 %)?
-- Neexistuje takový rok. Nejvyšší rozdíl mezi těmito nárusty byl 6,6 %.
 SELECT res.payroll_year, res.rozdil_cena * 100 , res.rozdil_mzda * 100, res.rozdil_cena * 100 - res.rozdil_mzda * 100
 FROM (
	SELECT act.payroll_year, (act.prumerna_cena - prev.prumerna_cena)/prev.prumerna_cena AS rozdil_cena,
		(act.prumerna_mzda - prev.prumerna_mzda)/prev.prumerna_mzda AS rozdil_mzda
	FROM (
		SELECT a.payroll_year, AVG(a.prumerna_cena) AS prumerna_cena, AVG(a.prumerna_mzda) AS prumerna_mzda
		FROM t_beata_davidova_project_SQL_primary_final a
		GROUP BY a.payroll_year ) act
	LEFT JOIN (
	    SELECT b.payroll_year, AVG(b.prumerna_cena) AS prumerna_cena, AVG(b.prumerna_mzda) AS prumerna_mzda
		FROM t_beata_davidova_project_SQL_primary_final b
		GROUP BY b.payroll_year) prev ON act.payroll_year = prev.payroll_year+1
 ) res
 WHERE res.rozdil_cena - res.rozdil_mzda > 0.05
	;
 SELECT * from t_beata_davidova_project_sql_primary_final tbdpspf 

/* 5. Má výška HDP vliv na změny ve mzdách a cenách potravin? Neboli, pokud HDP vzroste výrazněji v jednom roce, 
projeví se to na cenách potravin či mzdách ve stejném nebo násdujícím roce výraznějším růstem? 
*/

-- SELECT pro druhou tabulku
CREATE OR REPLACE TABLE t_beata_davidova_project_SQL_secondary_final AS
SELECT c.country, year, GDP AS hdp, gini, c.population 
	FROM  economies e 
	join countries c on c.country  = e.country 
	WHERE year BETWEEN 2006 AND 2018
		and c.continent  = 'Europe'	;
	
/*Jediný větší nárust HDP (nad 5%) nastal v letech 2007, 2015 a 2017. Meziroční změna cen a mezd však těchto letech i v následujích kolísá a obecně se nedá říct,
 že by tam takový trend byl. Hlubší statistické zkoumání na větším vzorku by bylo na místě.
*/
SELECT res.year, rozdil_hdp *100 , res2.rozdil_cena *100 , res2.rozdil_mzda *100 , res3.rozdil_cena *100  as rozdil_cena_nasledujici_rok, res3.rozdil_mzda *100  as rozdil_mzda_nasledujici_rok
FROM (
	SELECT act.year, (act.hdp - prev.hdp)/prev.hdp AS rozdil_hdp
	FROM (
		SELECT a.year, a.hdp
		FROM t_beata_davidova_project_SQL_secondary_final a
		WHERE country = 'Czech Republic'
		GROUP BY a.year) act
	LEFT JOIN (
	    SELECT b.year, b.hdp
		FROM t_beata_davidova_project_SQL_secondary_final b
		WHERE country = 'Czech Republic'
		GROUP BY b.year) prev ON act.year = prev.year+1 
) res -- růst HDP
LEFT JOIN (SELECT act.payroll_year, (act.prumerna_cena - prev.prumerna_cena)/prev.prumerna_cena AS rozdil_cena,
		(act.prumerna_mzda - prev.prumerna_mzda)/prev.prumerna_mzda AS rozdil_mzda
	FROM (
		SELECT a.payroll_year, AVG(a.prumerna_cena) AS prumerna_cena, AVG(a.prumerna_mzda) AS prumerna_mzda
		FROM t_beata_davidova_project_SQL_primary_final a
		GROUP BY a.payroll_year ) act
	LEFT JOIN (
	    SELECT b.payroll_year, AVG(b.prumerna_cena) AS prumerna_cena, AVG(b.prumerna_mzda) AS prumerna_mzda
		FROM t_beata_davidova_project_SQL_primary_final b
		GROUP BY b.payroll_year) prev ON act.payroll_year = prev.payroll_year+1
	) res2 ON res.year = res2.payroll_year -- růst cen a mezd ve stejném rove
LEFT JOIN (SELECT act.payroll_year, (act.prumerna_cena - prev.prumerna_cena)/prev.prumerna_cena AS rozdil_cena,
		(act.prumerna_mzda - prev.prumerna_mzda)/prev.prumerna_mzda AS rozdil_mzda
	FROM (
		SELECT a.payroll_year, AVG(a.prumerna_cena) AS prumerna_cena, AVG(a.prumerna_mzda) AS prumerna_mzda
		FROM t_beata_davidova_project_SQL_primary_final a
		GROUP BY a.payroll_year ) act
	LEFT JOIN (
	    SELECT b.payroll_year, AVG(b.prumerna_cena) AS prumerna_cena, AVG(b.prumerna_mzda) AS prumerna_mzda
		FROM t_beata_davidova_project_SQL_primary_final b
		GROUP BY b.payroll_year) prev ON act.payroll_year = prev.payroll_year+1
	) res3 on res.year +1 = res3.payroll_year 	; -- růst cen a mezd v naáledujícím roce
