# HR Dataset EDA Project

Four notebooks implement profiling, cleaning, visual EDA, statistical tests, time analysis, feature engineering, and final insights. Install dependencies with `pip install -r requirements.txt` and run notebooks 01 through 04 in order from the `notebooks/` directory.

## Data and privacy
The bundled raw source retains Employee_Name and DOB for the Day 2 cleaning exercise; original employee IDs are replaced with stable random project keys so duplicate records can be audited. Day 2 normalizes and splits Employee_Name, parses DOB, applies the documented two-digit-year correction, and derives age at hire. It removes names, exact DOBs, and source IDs before saving interim and processed analysis data; age_at_hire is retained. The raw names and pseudonymous workforce data remain sensitive; do not publish the raw file without authorization.

DOB-based age analysis is omitted because the mixed two-digit DOB values are ambiguous and DOB is sensitive. Employee-level sample rows are not displayed in Day 1. The duplicate audit exports only pseudonymous IDs, group sizes, and conflicting column names.

## Cleaning decisions
Day 2 is the cleaning source of truth and regenerates `data/interim/cleaned_day2.csv` from `data/raw/HRDataset_EDA_raw.csv`. It audits repeated IDs before dropping them; after normalizing text, all repeated-ID records agree on non-ID fields. The output has one row per employee (5,500 rows). Source categories are standardized to the documented labels, dates use a shared `AS_OF_DATE` of 2026-10-29, and every correction has a flag.

DOB dates use month/day for slash formats and day-month-year for dash formats. Two-digit DOB years are corrected to the 1900s when they fall in the future or imply age below 18 at hire; ambiguous dash dates follow the documented day-first assumption. Exact DOB is removed after age_at_hire is derived, and ages outside 18–70 are flagged. Hire/termination dates after the analysis date are flagged and nulled; unresolved termination-before-hire dates are flagged and nulled, while numeric dash dates are checked for a day/month swap. Active status is treated as the status source of truth and active termination dates are cleared.

Salary values are corrected by a factor of ten only when the adjusted value falls within position-peer 1st-99th percentile bounds; otherwise they are nulled. Negative absences are nulled; values above 60 are retained and flagged without clipping. Impossible days-late values above 30 are nulled and flagged. Statistical tests include assumption checks and effect sizes; all findings are associational, not causal.

## Outputs
Notebook 03 exports figures to `reports/figures/`. Notebook 04 writes `data/processed/final_cleaned_day4.csv`. One-person/small position groups are combined or suppressed in analysis views. Turned/terminated proportions are not annual turnover rates because the dataset lacks a defined annual population denominator.
