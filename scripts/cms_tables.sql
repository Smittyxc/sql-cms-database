/* 
	Author: Matthew Smith
    Email: mattsmith1652@gmail.com
    
    File Name: cms_tables.sql
    Description: This script will create tables, a schema, and relationships for three sets of CMS data. Additionally, 
    data is loaded from CSV files into landing tables and processed, with unnecessary table being droppped upon completion.
*/
    
DROP DATABASE if exists cms_vbi;    
CREATE DATABASE cms_vbi;

#Creates landing table for Disproportionate Share Hospitals, which data is loaded into.
DROP TABLE IF EXISTS cms_dsh_landing;
CREATE TABLE cms_dsh_landing (
	id INT,
    dsh_status VARCHAR(5),
    pr_ihs VARCHAR(3),
    rural VARCHAR(3),
    new_hosp VARCHAR(3),
    ucc_2020 VARCHAR(20),
    fact3 VARCHAR(20),
    total_ucc VARCHAR(20),
    cost_per_claim VARCHAR(20),
    avg20_21claims VARCHAR(20)
);    
LOAD DATA LOCAL INFILE 'MattSmith1652/cms_vbi/csv/cms_dsh.csv'
	INTO TABLE cms_dsh_landing
	FIELDS TERMINATED BY ','
	ENCLOSED BY '"'
	LINES TERMINATED BY '\r\n'
	IGNORE 1 ROWS
	(id,
    dsh_status, 
    pr_ihs, rural, 
    new_hosp, 
    @dummy, 
    @dummy, 
    @dummy, 
    @dummy, 
    ucc_2020, 
    @dummy, 
    fact3, 
    total_ucc, 
    @dummy, 
    cost_per_claim, 
    @dummy, 
    @dummy, 
    avg20_21claims
);

#Creates a table to process and hold DSH data, while filtering Puerto Rican, rural, new, and hospitals not receiving DSH payments due to alternative CMS funding algorithms.
DROP TABLE IF EXISTS cms_dsh;
CREATE table cms_dsh as SELECT id, 
	dsh_status, 
    pr_ihs, 
    rural, 
    new_hosp, 
	cast(IF(ucc_2020='', null, ucc_2020) AS DECIMAL(14,2)) AS ucc_2020,
	cast(IF(fact3='N/A', NULL, fact3) AS DECIMAL(15, 14)) AS fact3,
    cast(IF(total_ucc='N/A', NULL, total_ucc) AS DECIMAL(14,2)) AS total_ucc,
    cast(IF(cost_per_claim='N/A', NULL, cost_per_claim) AS DECIMAL(10,2)) AS cost_per_claim,
	cast(IF(TRIM(avg20_21claims)='N/A', NULL, avg20_21claims) AS DOUBLE) AS avg20_21claims
FROM cms_vbi.cms_dsh_landing
WHERE pr_ihs like 'NO' 
	AND rural like 'NO' 
	AND new_hosp like 'NO' 
    AND dsh_status IN('YES', 'SCH');
ALTER TABLE cms_dsh ADD PRIMARY KEY (id);

#Table is created to hold data loaded from Efficiency and Cost Reduction dataset.
DROP TABLE IF EXISTS cms_ecr_landing;
CREATE TABLE cms_ecr_landing (
	id INT,
    facility_name VARCHAR(70),
    state VARCHAR(5),
	mspb_achthres DECIMAL(6,5),
    mspb_bench DECIMAL(6,5),
    mspb_base VARCHAR(15),
    mspb_perf VARCHAR(15)
);
LOAD DATA LOCAL INFILE 'MattSmith1652/cms_vbi/csv/cms_ecr.csv'
	INTO TABLE cms_ecr_landing
	FIELDS TERMINATED BY ','
	ENCLOSED BY '"'
	LINES TERMINATED BY '\r\n'
	IGNORE 1 ROWS
	(@dummy, 
    id, 
    facility_name, 
    @dummy, 
    @dummy, 
    state, 
    @dummy, 
    @dummy, 
    mspb_achthres, 
    mspb_bench, 
    mspb_base, 
    mspb_perf, 
    @dummy, 
    @dummy, 
    @dummy);
 
 #Creates table to process and hold Efficiency and Cost Reduction data.
DROP TABLE IF EXISTS cms_ecr;
CREATE TABLE cms_ecr AS SELECT id, 
	facility_name, 
    state, 
    mspb_achthres, 
    mspb_bench,
	cast(IF(mspb_base='Not Available', NULL, mspb_base) AS DECIMAL(8,6)) AS mspb_base,
    cast(IF(mspb_perf='Not Available', NULL, mspb_perf) AS DECIMAL(8,6)) AS mspb_perf
FROM cms_vbi.cms_ecr_landing;
ALTER TABLE cms_ecr ADD PRIMARY KEY (id);

#Creates and loads Readmission Reduction data into a landing table.
DROP TABLE IF EXISTS cms_hrrp_landing;
CREATE TABLE cms_hrrp_landing ( 
    facility VARCHAR(90), 
    id INT, 
    state VARCHAR(5),
    measure VARCHAR(50), 
    dc_count VARCHAR(4),
    excess_rrt VARCHAR(6),
    predicted_rr VARCHAR(7),
    expected_rr VARCHAR(7),
    readm_count VARCHAR(18)
);
LOAD DATA LOCAL INFILE 'MattSmith1652/cms_vbi/csv/hrrp.csv'
	INTO TABLE cms_hrrp_landing
	FIELDS TERMINATED BY ','
	ENCLOSED BY '"'
	LINES TERMINATED BY '\r\n'
	IGNORE 1 ROWS
	(facility, 
    id, 
    state, 
    measure, 
    dc_count, 
    @dummy, 
    excess_rrt, 
    predicted_rr, 
    expected_rr, 
    readm_count, 
    @dummy, 
    @dummy);

#Creates table to process and hold HRRP data, exlcluding data that was eliminated in the previous two tables.
DROP TABLE IF EXISTS cms_hrrp;
CREATE table cms_hrrp as SELECT cms_hrrp_landing.id,
	cms_hrrp_landing.id AS id2,
    cms_hrrp_landing.facility, 
    cms_hrrp_landing.state, 
    cms_hrrp_landing.measure, 
	cast(IF(dc_count IN('N/A', 0), NULL, dc_count) AS DECIMAL(10,0)) AS dc_count,
    cast(IF(readm_count IN('N/A', 'Too Few to Report'), NULL, readm_count) AS DECIMAL(10,0)) AS readm_count,
	cast(IF(excess_rrt='N/A', NULL, excess_rrt) AS DECIMAL(6,5)) AS excess_rrt,
    cast(IF(predicted_rr='N/A', NULL, predicted_rr) AS DECIMAL(8,5)) AS predicted_rr,
    cast(IF(expected_rr='N/A', NULL, expected_rr) AS DECIMAL(8,5)) AS expected_rr
FROM cms_hrrp_landing
	LEFT JOIN cms_dsh 
		ON cms_dsh.id = cms_hrrp_landing.id
	LEFT JOIN cms_ecr
		ON cms_ecr.id = cms_hrrp_landing.id
WHERE cms_ecr.id IS NOT NULL AND cms_dsh.id IS NOT NULL;
ALTER TABLE cms_hrrp 
	ADD FOREIGN KEY (id) REFERENCES cms_dsh(id),
    ADD FOREIGN KEY (id2) REFERENCES cms_ecr(id);

#Tables no longer used are dropped
DROP TABLE cms_dsh_landing;
DROP TABLE cms_hrrp_landing;
DROP TABLE cms_ecr_landing;
