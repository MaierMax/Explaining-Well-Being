/*** ESP_01_sumstats.do
This file creates the dataset ESP_01.dta using the ECHP and ECPF surveys. 
The ECHP survey does not contain information on consumption. The ECPF survey does not contain information on leisure.
First run READING.do to read in the raw ECHP survey data (for all countries and all waves). -8=N/A -9=missing 
And READECPF.do to read in ECPF data for 2001. ***/

set more off
clear all

/* set directory - change as appropriate */
*cd "C:\Users\neryvia\PhD\RA Work\Rawls\Spain\"
cd "C:\Users\Rui\Dropbox\Beyond_GDP\ESP\Spain-ECHP"

// Data from the ECHP survey
/* parameters used */
local weeks = 43.1 			// OECD implied average weeks worked per worker 

/* keep only Spain from wave 8 (2001) files */
use a_w8h.dta, clear	// household file 
keep if country==11
save a_w8hesp.dta, replace

use a_w8p.dta, clear	// personal file
keep if country==11
save a_w8pesp.dta, replace

use a_w8r.dta, clear	// register file
keep if country==11
save a_w8resp.dta, replace

use a_w8rel.dta, clear	// relationship file
keep if country==11
save a_w8relesp.dta, replace

/* merge register, personal and household files */
// register file contains information on all interviewed individuals
use a_w8resp.dta, clear	
// personal file contains information on age>=16
merge 1:1 hid pid using a_w8pesp.dta, keepusing(pg002 pg003 pg005 pg006 pg007 pd004 pe001 pe001a pe002 pe002a pe003 pe004 pe005 pe005a pe005b pe005c pe011 pe012 pe014 pe015) gen(_mergep)
label var _mergep "Personal file merge results"
// household file contains information on household
merge m:1 hid using a_w8hesp.dta, keepusing(hd001 hd002 hd002a hd003 hi020 hi100) gen(_mergeh)
label var _mergeh "HH file merge results"

/* rename variables to be used */
rename hid hhid
rename rd003 age

***[Rui: create hhsize before dropping any observation]
* Create hhsize variable (Household Size) determined by number of observations for each Household ID
sort hhid
by hhid: gen hhsize=_N
lab var hhid "Household Size"


/* drop age <=0 and >100 */
drop if age <= 0
* 4 individuals with age=-9 (missing) and 105 individuals with age=0
drop if age > 100
* no individuals with age > 100

/* generate person code with household sorted by age in descending order */
gsort +hhid -age
by hhid: gen pcode = _n


/* calculate annual hours worked using OECD average weeks worked */
gen annualhrs = pe005*`weeks'		
replace annualhrs=8*`weeks' if pe005==-8 & pe003==2 					// hrs worked = N/A but ILO labour status = employed for less than 15 hours per week, assume worked 8 hrs per week	
replace annualhrs=. if pe005==-9										// hrs worked coded as missing						
replace annualhrs=0 if age<16 & _mergep==1								// under 16 not interviewed about employment
replace annualhrs=0 if pe005==-8 & (pe003==3 | pe003==4 | pe003==5)		// hrs worked = N/A and ILO labour status = unemployed/discouraged/inactive
replace annualhrs=. if age>=16 & _mergep==1								// individuals 16 and over with no personal interview
replace annualhrs=. if pe005==-8 & pe003==1 							// hrs worked = N/A but ILO labour status = employed for more than 15 hours per week
replace annualhrs=. if pe005==-8 & pe003==-9							// hrs worked = N/A and ILO labour status is missing (just one person)

label var annualhrs "Annual hours worked"

/* calculate leisure */
gen leisure = (5840 - annualhrs)/5840

svyset [pweight=rg002]
*svymean hhsize age leisure  // Stata 10 format
svy: mean hhsize age leisure  // Stata 11 format

/* normalise weights to sum to 1 */
summ rg002
gen weight=rg002/r(sum)
lab var weight "Normalized Individual Weight"

drop if leisure ==.
keep hhid hhsize age leisure weight
order hhid hhsize age leisure weight
save "C:\Users\Rui\Dropbox\Beyond_GDP\ESP\ESP_01_ECHP.dta", replace 
format weight %11.4e
outfile using "C:\Users\Rui\Dropbox\Beyond_GDP\ESP\ESP_01_leisure.txt", wide replace 


// Data from the ECPF survey
cd "C:\Users\Rui\Dropbox\Beyond_GDP\ESP\Spain-ECPF\ReadData"				// ECPF expenditure data for 2001, q1 to q4
use "exp01.dta", clear
gen ndexp = 1
/* excluded from nondurable expenditure */
replace ndexp = 0 if floor(codigo/10000)==43		// 4.3 Routine maintenance and repair of the housing
replace ndexp = 0 if floor(codigo/10000)==51		// 5.1 Furniture, furnishings, carpets and other floor coverings and repairs
replace ndexp = 0 if floor(codigo/10000)==52		// 5.2 Household textiles and repairs
replace ndexp = 0 if floor(codigo/10000)==53		// 5.3 Major and small household appliances and repairs and accessories of all home appliances
replace ndexp = 0 if floor(codigo/1000)==551		// 5.5.1 Major tools for house and garden, and repairs of these tools
replace ndexp = 0 if floor(codigo/10000)==71		// 7.1 Purchase of vehicles
replace ndexp = 0 if floor(codigo/1000)==721		// 7.2.1 Purchase of spare parts and accessories of personal vehicles for repairs by hh members
replace ndexp = 0 if floor(codigo/1000)==723		// 7.2.3 Maintenance and repairs of vehicles
replace ndexp = 0 if floor(codigo/1000)==812		// 8.1.2 Telephone and fax equipment
replace ndexp = 0 if floor(codigo/10000)==91		// 9.1 Equipment and audio-visual and photographic processing information, including its repairs
replace ndexp = 1 if floor(codigo/1000)==914		// But include 9.1.4 Support for recording image and sound (CDs, cassettes, etc)
replace ndexp = 0 if floor(codigo/10000)==92		// 9.2. Other major durables for recreation and culture, and repairs
replace ndexp = 0 if floor(codigo/1000)==1221		// 12.2.1 Jewellery, clocks and watches
replace ndexp = 0 if floor(codigo/10000)==128		// 12.8 Remittances to non-resident household members

/* generate consumption measure */
sort nidentif year quarter ndexp
collapse (sum) importe, by(nidentif year quarter ndexp)
drop if ndexp==0
drop ndexp 
replace importe = importe/166.386			// convert from pesetas to euros
sort nidentif year quarter
by nidentif: egen hhexp = mean(importe)		// average expenditure

/* count number of quarters hh is in survey */
bysort nidentif: egen no_quarters = count(hhexp)
tab no_quarters

/* get household weight, income, and degree of collaboration */
rename year ano					// for merge compatibility
rename quarter tri 				// for merge compatibility
merge 1:1 nidentif ano tri using home01.dta, keep(master matched) keepusing(factor importem gcolab gasto) 
drop _merge

/* generate income measure - income amount missing for most hh */
bysort nidentif: egen avg_monthly_hhinc = mean(importem)
gen hhinc = avg_monthly_hhinc * 12

/* normalise weights to sum to 1 */
forvalues quarter = 1/4 {
	summ factor if gcolab==1 & tri==`quarter'							// strong collaboration households
	*local sumfactor`quarter' = r(sum)					
	replace factor = 0.5 * factor/r(sum) if gcolab==1 & tri==`quarter'
	summ factor if gcolab==6 & tri==`quarter'							// weak collaboration households	
	*local sumfactor`quarter' = `sumfactor`quarter'' + r(sum)										
	replace factor = 0.5 * factor/r(sum) if gcolab==6 & tri==`quarter'
}

/* calculate average hh weight */
sort nidentif ano tri
bysort nidentif: egen hhweight = mean(factor)

lab var hhweight "Normalized Household Weight"

/* keep only last observation per hh */
sort nidentif ano tri
by nidentif: drop if _n!=_N

/* get household member ages */
rename ano year
rename tri quarter
merge 1:m nidentif year quarter using hhmem01.dta, keep(master matched) keepusing(nordenp edad)
drop _merge

rename nidentif hhid
* Create hhsize variable (Household Size) determined by number of observations for each Household ID
bysort hhid: gen hhsize=_N
lab var hhid "Household Size"

/* drop age <=0 and >100 */
drop if edad <= 0
* 158 individuals with age=0
drop if edad > 100
* 1 individual with age > 100

rename nordenp personid
rename edad age

/* generate person code with household sorted by age in descending order */
gsort +hhid -age
by hhid: gen pcode = _n

*normalize weights to sum to 1
summ hhweight
gen weight=hhweight/r(sum)
lab var weight "Normalized Individual Weight"


keep hhid hhsize age hhexp weight
order hhid hhsize age hhexp weight
format hhid %20.0f
save "C:\Users\Rui\Dropbox\Beyond_GDP\ESP\ESP_01_ECPF.dta", replace
format weight %11.4e
outfile using "C:\Users\Rui\Dropbox\Beyond_GDP\ESP\ESP_01_exp.txt", wide replace

 



