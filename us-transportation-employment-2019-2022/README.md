# US Transportation Employment (2019–2022)

Author: Runzhi Li  

## Overview
This project analyzes county-level employment in the U.S. transportation sector, comparing 2019 and 2022.  
The goal is to examine how employment changed across regions before and after the COVID-19 pandemic,  
and to visualize both absolute employment and growth rates.  

## Workflow
1. **Python (`code/01_calc_growth_rates.ipynb`)**  
   - Cleans the raw census data  
   - Calculates employment growth rates (2019 → 2022)  
   - Outputs: `data/processed/employment_growth_rate.csv`  

2. **R (`code/02_map_emp_growth.R`)**  
   - Loads the shapefiles and processed data  
   - Generates county-level employment maps and growth-rate maps  
   - Outputs: `outputs/Results_Emp&Growth.pdf`  

## Folder Structure
- `code/` — Python + R scripts  
- `data/raw/` — Raw shapefiles and census CSVs  
- `data/processed/` — Processed dataset (`employment_growth_rate.csv`)  
- `outputs/` — Final PDF visualization  

## Data Source
U.S. Census Bureau, County Business Patterns (NAICS 48: Transportation). 
