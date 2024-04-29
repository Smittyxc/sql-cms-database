# CMS Value Based Programs Financial and Readmission MySQL Database

- **Author**: Matthew Smith

- **Email**: mattsmith1652@gmail.com

## Background
Beginning with the passage of the Medicare Improvements for Patients and Providers Act and the Afforadable Care Act in 2008 and 2010, respectively, the CMS debuted a set of [Value-Based Programs](https://www.cms.gov/medicare/quality/value-based-programs) to reward health care systems in proportion to the quality of care they provide to Medicare patients. The initiatives aim to improve patient outcomes and the hospital experience for patients by, principally, withholding 2% of Medicare payments and using this capital to fund the value-based incentive programs, which is distributed based on an individual claim adjustment factor applied to the predetermined Medicare severity diagnosis-related group (MS-DRG) payment amount.

## Analysis
Using MySQL, an analysis of the Centers for Medicare and Medicaid Value-Based Programs was performed. Although there are many VBPs, the Efficiency and Cost Reduction, Hospital Readmission Reduction, and Disproportionate Share Hospital Programs were selected for this analysis, as insights generate from them could show potential relationships between financial and readmission statistics.


## Datasets used
The three [datasets](cms_vbi/csv) are the latest release from CMS as of 3/26/2024. The COVID-19 pandemic altered the reporting schedule of many VBPs.
- **cms_dsh.csv**: [Disproportionate Share Hospital Program](https://www.cms.gov/medicare/payment/prospective-payment-systems/acute-inpatient-pps/disproportionate-share-hospital-dsh)
- **cms_ecr.csv**: [Efficiency and Cost Reduction Program](https://data.cms.gov/provider-data/dataset/su9h-3pvj)
- **cms_hrrp.csv**: [Hospital Readmission Reduction Program](https://www.cms.gov/medicare/quality/value-based-programs/hospital-readmissions)


## Entity Relationship Diagram
![eer](/assets/cms_eer.png)
