********************************************************
**PROGRAM 1: GENERATING COUNTRY DATASET IDN_06.DTA**
********************************************************

clear all


cd "C:\Users\Rui\Dropbox\Beyond_GDP\IDN\SUSENAS CORE 2006"

************************************************************
* Read the HH expenditure csv file
************************************************************
insheet using "ssn06kr.csv", clear

* name and label the variables
local i = 1
local varnames "hB1R1 hB1R2 hB1R3 hB1R4 hB1R5 hB1R7 hB1R8 hKOTA B6R1 B6R2 B6R3 B6R4 B6R5 B6R6A B6R6B B6R7 B6R8 B6R9A B6R9B B6R9C B6R10 B6R11A B6R11B B6R11C B7R1A B7R1B B7R2 B7R3A B7R3B B7R4 B7R5A B7R5B B7R6 B7R7 B7R8 B7R9 B7R10 B7R11 B7R12A B7R12B B7R13A B7R13B B7R13C B7R14A B7R14B B7R15 B7R16A2 B7R16A3 B7R16B2 B7R16B3 B7R16C2 B7R16C3 B7R16D2 B7R16D3 B7R17A2 B7R17A3 B7R17B2 B7R17B3 B7R17C2 B7R17C3 B7R17D2 B7R17D3 B7R17E2 B7R17E3 B7R182 B7R183 B7R192 B7R193 B7R20A2 B7R20A3 B7R20B2 B7R20B3 B7R20C2 B7R20C3 B7R20D2 B7R20D3 B7R212 B7R213 B7R222 B7R223 B7R23 B7R24 B7R25 B7R26A B7R26B B8R1A B8R1B1 B8R1B2 B8R2A B8R2B B8R3A B8R3B B8R3C B8R4A B8R4B B8R5A B8R5B12 B8R5B13 B8R5B22 B8R5B23 B8R5B32 B8R5B33 B8R5B42 B8R5B43 B8R5B52 B8R5B53 B8R5B62 B8R5B63 B8R5B72 B8R5B73 B9R1 B9R2A B9R2B B9R3 B9R4A B9R4B B9R5A2 B9R5A3 B9R5B2 B9R5B3 B9R5C2 B9R5C3 B2R2 WERT"

foreach x of local varnames {
	rename v`i' `x'
	local i = `i'+1
}

** Create household consumption measures
*
* Categories to include:
label var B7R15     "Total food (weekly only)"
*
*  Monthly(2) and Annual(3 as last digit)
*  Note: including home maintenance/repairs to be consistent w/ 1993 data.
label var B7R16A2   "leases, contracts, estimates of the rent"
label var B7R16B2   "home maintenance and minor repairs"
label var B7R16C2   "electricity bills, telephone, gas, kerosene"
label var B7R16D2   "home telephone account, pulse hp, telephone um"
label var B7R17A2   "toilet soap / laundry, cosmetics, care ramb"
label var B7R17B2   "health costs (per month)"
label var B7R17C2   "cost of education (a month)"
label var B7R17D2   "transportation, transportation, gasoline, diesel, m"
label var B7R17E2   "other services (month)"
label var B7R182    "clothing, footwear and headgear (sebu"

* Excluded categories
label var B7R192    "durable goods (a month)"
label var B7R20A2   "tax (UN, vehicle) (month)"
label var B7R20B2   "levies / charges (a month)"
label var B7R20C2   "health insurance (a month)"
label var B7R20D2   "Other (a month)"
label var B7R212    "feast and ceremonial purposes (month)"

* Extra aggregates, not used
label var B7R222    "Total, non-food (one month)"
label var B7R23     "Average spending on food a month"
label var B7R24     "Average spending on non-food sebu"
label var B7R25     "Average household expenditure sebul"

save "ssn06kr.dta",replace

use "ssn06kr.dta",clear
* Fix the HHID = hB1R1#hB1R2#hB1R3#hB1R4#hB1R7#hB1R8   
* Replace "space" with "0" --> '01' not ' 1'
tostring hB1R1, g(hhid1) format(%02.0f)
tostring hB1R2, g(hhid2) format(%02.0f)
tostring hB1R3, g(hhid3) format(%03.0f)
tostring hB1R4, g(hhid4) format(%03.0f)
tostring hB1R7, g(hhid5) format(%06.0f)
tostring hB1R8, g(hhid6) format(%02.0f)

gen iHHID = hhid1+hhid2 + hhid3+hhid4+hhid5+hhid6

* number of households: 277202
codebook iHHID
* Note well:  B7R15 is *weekly* food expenditure data.
*             B7R23 converts to *monthly* by *30/7.
gen MonthlyFood=B7R23
gen MonthlyNonFood=B7R16A2+B7R16B2+B7R16C2+B7R16D2+B7R17A2+B7R17B2+B7R17C2+B7R17D2+B7R17E2+B7R182
gen AnnualNonFood =B7R16A3+B7R16B3+B7R16C3+B7R16D3+B7R17A3+B7R17B3+B7R17C3+B7R17D3+B7R17E3+B7R183
gen MonthlyTotal=MonthlyFood+MonthlyNonFood
gen AnnualTotal=MonthlyFood*12+AnnualNonFood

gen food1=MonthlyFood*12/AnnualTotal //No durables
gen food2=B7R23/B7R25 //Includes durables in denominator

* Check that B7R15 really is the sum of the food categories:
gen food=B7R1A+ B7R1B+ B7R2 + B7R3A+ B7R3B+ B7R4 + B7R5A+ B7R5B+ B7R6 +B7R7 + B7R8 + B7R9 + B7R10 + B7R11 + B7R12A+ B7R12B+ B7R13A+B7R13B+ B7R13C+ B7R14A+ B7R14B

label var food1 "Food share 1: excludes durables"
label var food2 "Food share 2: includes durables"

gen hhexp = AnnualTotal

rename iHHID hhid
keep hhid hhexp
save "Indonesia2006HH.dta",replace

********************************
* Individual data
********************************

insheet using "ssn06ki.csv",clear
local i = 1
local varnames "B1R1 B1R2 B1R3 B1R4 B1R5 B1R7 B1R8 NART HB JK UMUR KWN JAHAT FREK LAHIR PRASKL NO_IBU INFO B5R1A B5R1B B5R1C B5R1D B5R1E B5R1F B5R1G B5R1H B5R2 B5R3 B5R4 B5R5A B5R5B1 B5R5B2 B5R5B3 B5R6 B5R7A B5R7B B5R7C B5R7D B5R7E B5R7F B5R7G B5R7H B5R8 B5R9A B5R9B B5R9C B5R9D B5R9E B5R9F B5R10A B5R10B B5R10C B5R10D B5R10E B5R10F B5R10G B5R11A B5R11B B5R12A B5R12B B5R13A B5R13B B5R13C B5R13D B5R13E B5R14A B5R14B1 B5R14B2 B5R14B3 B5R15 B5R16A B5R16B B5R17 B5R18 B5R19 B5R20 B5R21 B5R22A1 B5R22A2 B5R22A3 B5R22A4 B5R22B B5R23 B5R24 B5R25 B5R26 B5R27A B5R27B B5R28 B5R29 B5R30 B5R31 B5R32 B5R33 B5R34A1 B5R34A2 B5R34A3 B5R34B1 B5R34B2 B5R34B3 B5R34C1 B5R34C2 B5R34C3 B5R35 B5R36 iKOTA WEIND"
foreach x of local varnames{ 
	rename v`i' `x'
	local i = `i'+1
}
save "ssn06ki.dta", replace

use "ssn06ki.dta",clear
rename NART PCODE
gen age = UMUR+1
rename WEIND weight
* Fix the HHID = B1R1#B1R2#B1R3#B1R4#B1R9#B1R10    
* Replace "space" with "0" --> '01' not ' 1'
tostring B1R1, g(hhid1) format(%02.0f)
tostring B1R2, g(hhid2) format(%02.0f)
tostring B1R3, g(hhid3) format(%03.0f)
tostring B1R4, g(hhid4) format(%03.0f)
tostring B1R7, g(hhid5) format(%06.0f)
tostring B1R8, g(hhid6) format(%02.0f)

gen iHHID = hhid1+hhid2 + hhid3+hhid4+hhid5+hhid6

bysort iHHID: gen hhsize = _N

* leisure
rename B5R27B hoursworked
replace hoursworked = 0 if B5R22A1!=1 & hoursworked == .
scalar WeeksPerYear = 52
gen leisure = 1-WeeksPerYear*hoursworked/(365*16)
rename iHHID hhid
format hoursworked %8.0f
format leisure %8.3f

keep hhid age leisure weight hhsize
save "Indonesia2006ind.dta",replace

***************************
* merge two data sets
***************************
use "Indonesia2006ind.dta",clear
merge m:1 hhid using "Indonesia2006HH.dta"
keep if _merge == 3
drop _merge
egen weight_sum = sum(weight)
replace weight = weight/weight_sum
* hhid kept as string because of round up of double precision
sum hhid age hhsize hhexp leisure weight
keep hhid hhsize age hhexp leisure weight
order hhid hhsize age hhexp leisure weight
save "IDN_06.dta",replace
format hhexp %10.0f
format weight %11.4e
outfile using "IDN_06.txt",replace noquote wide
