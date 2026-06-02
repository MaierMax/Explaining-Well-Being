********************************************************
**PROGRAM 1: GENERATING COUNTRY DATASET IDN_93.DTA**
********************************************************

clear all


cd "C:\Users\Rui\Dropbox\Beyond_GDP\IDN\SUSENAS CORE 1993"

************************************************************
* Read the HH expenditure csv file
************************************************************
insheet using "Ssn93kr2.csv", clear

* name and label the variables
local i = 1
local varnames "B1R1 B1R2 B1R3 B1R4 B1R5 B1R9 B1R10 CD B2R2 FILLE TY100 B2R3 B2R4 B2R5 B2R6 TY130 B8R1 B8R2 B8R3 B8R4 B8R5 B8R6 B8R7 B8R8 B8R9 TY140 B9K1 B9K2 B9K3 B9R39 INDIV HHRT"
foreach x of local varnames {
	rename v`i' `x'
	local i = `i'+1
}

label var B1R1 "Province Code"
label var B1R2 "District Code"
label var B1R3 "District Code"
label var B1R4 "Code Village / Village"
label var B1R9 "Number sample code"
label var B1R10 "Number of households sampled sequence"
label var B2R2 "Number of household members"
label var B9K1 "Number / type of expenditure"
label var B9K2 "Value a month / week ago"
label var B9K3 "Value a year ago"

save "Ssn93kr2.dta",replace

use "Ssn93kr2.dta",clear
* Fix the HHID = B1R1#B1R2#B1R3#B1R4#B1R9#B1R10    
* Replace "space" with "0" --> '01' not ' 1'
tostring B1R1, g(hhid1) format(%02.0f)
tostring B1R2, g(hhid2) format(%02.0f)
tostring B1R3, g(hhid3) format(%03.0f)
tostring B1R4, g(hhid4) format(%03.0f)
tostring B1R9, g(hhid5) format(%04.0f)
tostring B1R10, g(hhid6) format(%02.0f)

gen iHHID = hhid1+hhid2 + hhid3+hhid4+hhid5+hhid6

* number of households: 65553
codebook iHHID
drop INDIV HHRT
reshape wide B9K2 B9K3,i(iHHID) j(B9K1)

save "household_reshaped.dta",replace

* 17 = Housing, fuel, lighting,
* 18 = Miscellaneous goods and services - water &
* 19 = Cost of education
* 20 = The cost of health
* 21 = Clothing, footwear and headgear
* 22 = Durable goods
* 23 = Tax and insurance
* 24 = Needs a party and ceremony
* 25 = Number of non-food expenditure
* 26 = Average spending on food
*         month (details Q16 x 30 / 7)
* 27 = average non-food expenditure
*         a month (the details of 25 divided by 12)
* 28 = Average household expenditures
*         month (26 + detailed breakdown 27)

use "household_reshaped.dta",clear
gen MonthlyFood = B9K226
egen MonthlyNonFood = rowtotal(B9K217 B9K218 B9K219 B9K220 B9K221)
egen AnnualNonFood = rowtotal(B9K317 B9K318 B9K319 B9K320 B9K321)
gen MonthlyTotal = MonthlyFood + MonthlyNonFood
gen AnnualTotal = MonthlyFood*12+AnnualNonFood
gen foodshare=MonthlyFood*12/AnnualTotal

* Check that B9X16 really is the sum of the food categories:
egen food = rowtotal(B9K21 B9K22 B9K23 B9K24 B9K25 B9K26 B9K27 B9K28 B9K29 B9K210 B9K211 B9K212 B9K213 B9K214 B9K215)
drop if MonthlyFood == 0 | AnnualNonFood ==0
gen diff1 = abs(food - B9K216)
drop if diff1 > 1
gen diff2 = abs(B9K216*30/7-B9K226)
drop if diff2 > 1

destring iHHID,replace
format iHHID %20.0f
rename iHHID hHHID

gen Ratio = AnnualNonFood/MonthlyNonFood

*expenditure in local currency
gen hHHEXP = AnnualTotal
gen log_exp = log(hHHEXP)
hist log_exp,bin(100) xtitle("log HH consumpntion") ytitle("Frequency") frequency
keep hHHID hHHEXP
save "Indonesia1993HH.dta",replace


***************************
* read in individual data
***************************
insheet using "Ssn93ki.csv",clear
local i = 1
local varnames "B1R1 B1R2 B1R3 B1R4 B1R5 B1R9 B1R10 CD B2R2 FILLE TYPE1 B4K1 B4K3 B4K4 B4K5 B4K6 B4K7 B4K8 B4K9 B5R0 B5R1 B5R2 B5R3 B5R4 B5R5 B5R6 B5R7AK2 B5R7AK3 B5R7AK4 B5R7BK2 B5R7BK3 B5R7BK4 B5R7CK2 B5R7CK3 B5R7CK4 B5R7DK2 B5R7DK3 B5R7DK4 B5R7EK2 B5R7EK3 B5R7EK4 B5R7FK2 B5R7FK3 B5R7FK4 B5R7GK2 B5R7GK3 B5R7GK4 B5R7HK2 B5R7HK3 B5R7HK4 B5R7IK2 B5R8 B5R9 B5R10 B5R10A B5R10B B5R11 B5R12 B5R13A B5R13B B5R14 B5R15A B5R15B B5R16 B5R17 B5R18 B5R19 B6R20 B6R21 B6R22 B6R23A B6R23B B6R24 B6R25 B6R26 B6R27 B6R28 B6R29 B6R30 B7R31 B7R32A B7R32B B7R32C B7R33 B7R34 B7R35 INDIV HHRT"
foreach x of local varnames{ 
	rename v`i' `x'
	local i = `i'+1
}
save "Ssn93ki.dta", replace

use "Ssn93ki.dta",clear
rename B4K1 PCODE
gen age = B4K5+1
rename INDIV weight
* Fix the HHID = B1R1#B1R2#B1R3#B1R4#B1R9#B1R10    
* Replace "space" with "0" --> '01' not ' 1'
tostring B1R1, g(hhid1) format(%02.0f)
tostring B1R2, g(hhid2) format(%02.0f)
tostring B1R3, g(hhid3) format(%03.0f)
tostring B1R4, g(hhid4) format(%03.0f)
tostring B1R9, g(hhid5) format(%04.0f)
tostring B1R10, g(hhid6) format(%02.0f)

gen iHHID = hhid1+hhid2 + hhid3+hhid4+hhid5+hhid6

bysort iHHID: gen hhsize = _N

* leisure
rename B6R23B hoursworked
replace hoursworked = 0 if B6R20!=1 & hoursworked == .
scalar WeeksPerYear = 52
gen leisure = 1-WeeksPerYear*hoursworked/(365*16)
destring iHHID,replace
format iHHID %20.0f
rename iHHID hHHID
format hoursworked %8.0f
format leisure %8.3f

keep hHHID age leisure weight hhsize
save "Indonesia1993ind.dta",replace

***************************
* merge two data sets
***************************
use "Indonesia1993ind.dta",clear
merge m:1 hHHID using "Indonesia1993HH.dta"
keep if _merge == 3
drop _merge
rename hHHID hhid
rename hHHEXP hhexp
egen weight_sum = sum(weight)
replace weight = weight/weight_sum
sum hhid age hhsize hhexp leisure weight
keep hhid age hhsize hhexp leisure weight
order hhid hhsize age hhexp leisure weight
save "IDN_93.dta",replace
format weight %11.4e
outfile using "IDN_93.txt",replace wide
