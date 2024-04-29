/* 
	Author: Matthew Smith
    Email: mattsmith1652@gmail.com
    
    File Name: cms_vbi.sql
    Description: The following queries explore trends using the cms_vbi database, revealing potential insights in Medicare data. Many
    of the queries look to identify financial trends in relation to readmission rates at the faciltiy and state level.
*/

#Finds the average excess readmission ratio of poor performers, delineated by state and DRG. Think twice before getting hip replacements done in AK...
Select state, 
	AVG(excess_rrt) AS avg_excessrrt, 
    measure
FROM cms_vbi.cms_hrrp
WHERE excess_rrt > 1.0 
	AND excess_rrt IS NOT NULL
GROUP BY state, measure
ORDER BY avg_excessrrt DESC;

#From applicable hospitals, finds worst readmission offenders per state and DRG
SELECT state, 
	id, 
	facility, 
    measure, 
    excess_rrt
FROM (
	SELECT RANK() OVER(PARTITION BY measure, state ORDER BY excess_rrt DESC) AS state_rank, state, measure, facility, excess_rrt, id 
    FROM cms_vbi.cms_hrrp
    WHERE excess_rrt IS NOT NULL
    ORDER BY state_rank, state
    ) AS temp_hrrp
WHERE state_rank = 1;

#For each state, displays the facility with the highest readmission rate per state and DRG, and gives it's equivalent cost per claim rank as well.  
WITH temp_hrrp AS (
		SELECT facility, id, state, measure, excess_rrt, 
			RANK() OVER (PARTITION BY state, measure ORDER BY excess_rrt DESC) AS state_rank,
			CONCAT(id, '-', measure) AS id_measure
		FROM cms_vbi.cms_hrrp
		WHERE excess_rrt IS NOT NULL
),
	temp_dsh AS (
		SELECT cms_dsh.id, cms_hrrp.state, cms_hrrp.measure, cms_dsh.cost_per_claim, 
			RANK() OVER (PARTITION BY cms_hrrp.state, measure ORDER BY cost_per_claim DESC) AS cost_rank,
			CONCAT(cms_dsh.id, '-', measure) AS id_measure
		FROM cms_vbi.cms_dsh
			LEFT JOIN cms_vbi.cms_hrrp 
				ON cms_dsh.id = cms_hrrp.id
		WHERE cost_per_claim IS NOT NULL
)
SELECT hrrp.facility,
	hrrp.state,
    hrrp.id,
	hrrp.measure,
    hrrp.state_rank,
    dsh.cost_rank
FROM temp_hrrp hrrp
	LEFT JOIN temp_dsh dsh
		ON hrrp.id_measure = dsh.id_measure
WHERE hrrp.state_rank = 1
ORDER BY hrrp.state;

#For each state, calculates the ratio of faciltities performing beneath the standardized national expected readmission rate for a given DRG  
SELECT state, 
	measure,
	SUM(CASE WHEN excess_rrt>1 THEN 1 ELSE 0 END) AS underperform_count,
	SUM(CASE WHEN excess_rrt IS NOT NULL THEN 1 ELSE 0 END) AS facility_count, 
	SUM(CASE WHEN excess_rrt>1 THEN 1 ELSE 0 END)/SUM(CASE WHEN excess_rrt IS NOT NULL THEN 1 ELSE 0 END) AS underperform_rrt
FROM cms_vbi.cms_hrrp
GROUP BY state, measure;

#Queries data for potential correlation between Medicare Spending per Beneficiary Ratio and readmission rates per DRG. 
SELECT hrrp.state, 
	hrrp.facility, 
	hrrp.measure, 
	hrrp.excess_rrt, 
	ecr.mspb_perf
FROM cms_vbi.cms_ecr ecr
LEFT JOIN cms_vbi.cms_hrrp hrrp
	ON ecr.id = hrrp.id
    AND hrrp.measure like 'READM-30-COPD-HRRP';

#Queries data to identify correlations between readmission rates and Medicare cost per claims
SELECT dsh.id, 
	hrrp.excess_rrt, 
	dsh.cost_per_claim, 
	hrrp.measure
FROM cms_vbi.cms_dsh dsh
LEFT JOIN cms_vbi.cms_hrrp hrrp
	ON cms_dsh.id = cms_hrrp.id
    AND cms_hrrp.excess_rrt IS NOT NULL
WHERE cms_hrrp.measure like 'READM-30-HF-HRRP';

#Identifies geographic trends in cost per claims data, dividing Medicare cost per claim in quartiles per state, which can be used to grade individual facilities.
WITH facility_quartiles AS ( 
	SELECT NTILE(4) OVER(ORDER BY dsh.cost_per_claim) AS cpc_quart, 
		hrrp.measure,
		hrrp.state, 
		hrrp.excess_rrt, 
		dsh.cost_per_claim, 
		hrrp.facility
	FROM cms_vbi.cms_dsh dsh
	INNER JOIN cms_vbi.cms_hrrp hrrp
		ON dsh.id = hrrp.id
)
SELECT
	state,
	MIN(cost_per_claim) AS minimum,
	MAX(CASE WHEN cpc_quart=1 THEN cost_per_claim ELSE null END) AS quart1,
	MAX(CASE WHEN cpc_quart=2 THEN cost_per_claim ELSE null END) AS median,
	MAX(CASE WHEN cpc_quart=3 THEN cost_per_claim ELSE null END) AS quart3,
    MAX(cost_per_claim) as maximum
FROM facility_quartiles
GROUP BY state
ORDER BY state;

#Distinguishes if a readmission rate below 1 or above 1 are correlated with higher Medicare cost per claims.
SELECT
	state,
	ROUND(AVG(CASE WHEN cms_hrrp.excess_rrt>1 THEN cms_dsh.cost_per_claim END), 2) AS over1_cost,
	ROUND(AVG(CASE WHEN cms_hrrp.excess_rrt<1 THEN cms_dsh.cost_per_claim END), 2) AS under1_cost
FROM cms_vbi.cms_dsh
	INNER JOIN cms_vbi.cms_hrrp
		ON cms_dsh.id = cms_hrrp.id
GROUP BY cms_hrrp.state;