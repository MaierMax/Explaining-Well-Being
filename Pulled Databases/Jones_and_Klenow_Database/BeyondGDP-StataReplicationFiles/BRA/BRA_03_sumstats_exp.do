clear all
*cd "C:\Zach\Projects_Pete\Brazil\POF\Data_0203\Output"
cd "C:\Users\Rui\Dropbox\Beyond_GDP\BRA\Raw Data\Raw Data\POF\Data_0203\Output"
use "reg1.dta"

merge 1:m iddom using "reg2.dta"
drop _merge

*calculate hhsize before dropping any data

sort iddom
by iddom: gen hhsize=_N 

* keep the household where the consumption unit equals 1 (keeping more than 99.8% data)
drop if nuc ~=1


********************Rui *******************
*calculate hhsize by number of observations in each family
 
********************end edit **************
drop if idadcala==.
gen age = idadcala + 1
drop if age <= 0 
drop if age > 100

*test: hhsize and hhsize_data match perfectly
rename nmoradores hhsize_data
gen diff = hhsize - hhsize_data
tab diff

* transfer monthly income to annual income
gen hhinc = rentmenuc*12
drop if hhinc <=0
keep iddom factorxp1 factorxp2 age hhsize hhinc
save "Brazil_03_exp_raw.dta", replace

* Including Expenditure Code 19 
use "reg8.dta"
drop if nuc ~=1
by iddom, sort: egen exp_19 = sum(valdefanu) 
label var exp_19 "annualized value of expenditure code 19"
keep iddom exp_19
* Delete the duplicates
sort iddom
duplicates drop iddom, force

merge 1:m iddom using "Brazil_03_exp_raw.dta"
drop _merge
save "Brazil_03_exp_raw.dta", replace

* Including Expenditure Code 22 - 50, excluding 48
use "reg10.dta"
drop if nquadro == 48
drop if nuc ~=1
by iddom, sort: egen exp_22_50 = sum(valdefanu) 
label var exp_22_50 "annualized value of expenditure code 22-50"
keep iddom exp_22_50
* Delete the duplicates
sort iddom
duplicates drop iddom, force

merge 1:m iddom using "Brazil_03_exp_raw.dta"
drop _merge
save "Brazil_03_exp_raw.dta", replace

* Including Expenditure Code 18
use "reg7.dta"
keep if nquadro == 18
drop if nuc ~=1
by iddom, sort: egen exp_18 = sum(valdefanu) 
label var exp_18 "annualized value of expenditure code 18"
keep iddom exp_18
* Delete the duplicates
sort iddom
duplicates drop iddom, force

merge 1:m iddom using "Brazil_03_exp_raw.dta"
drop _merge
save "Brazil_03_exp_raw.dta", replace

* Including Expenditure Code 10,12,13
use "reg6.dta"
drop if nquadro == 11
drop if nuc ~=1
by iddom, sort: egen exp_10_13 = sum(valdefanu) 
label var exp_10_13 "annualized value of expenditure code 10-13"
keep iddom exp_10_13
* Delete the duplicates
sort iddom
duplicates drop iddom, force

merge 1:m iddom using "Brazil_03_exp_raw.dta"
drop _merge
save "Brazil_03_exp_raw.dta", replace

* Including Expenditure Code 7
use "reg5.dta"
keep if nquadro == 7
drop if nuc ~=1
by iddom, sort: egen exp_7 = sum(valdefanu) 
label var exp_7 "annualized value of expenditure code 7"
keep iddom exp_7
* Delete the duplicates
sort iddom
duplicates drop iddom, force

merge 1:m iddom using "Brazil_03_exp_raw.dta"
drop _merge
save "Brazil_03_exp_raw.dta", replace

replace exp_18 = 0 if exp_18 ==.
replace exp_10_13 = 0 if exp_10_13 ==.
replace exp_7 = 0 if exp_7 ==.
replace exp_22_50 = 0 if exp_22_50 ==.
replace exp_19 = 0 if exp_19 ==.


gen hhexp = exp_7 + exp_10_13 + exp_18 + exp_19 + exp_22_50
drop if hhinc <=0
drop if hhexp <=0



label var hhexp "annualized household non-durables expenditure"
label var age "age"
label var hhsize "number of residents"
rename iddom hhid
label var hhid "household ID"
label var hhinc "annualized household income"

sort hhid
drop if age==.
drop if hhsize ==.
summ factorxp2
gen weight=factorxp2/r(sum)
lab var weight "Normalized Individual Weight"


keep hhid hhsize age hhexp weight
order hhid hhsize age hhexp weight
save "C:\Users\Rui\Dropbox\Beyond_GDP\BRA\Calculation\BRA_03_exp.dta", replace
format weight %11.4e
outfile using "C:\Users\Rui\Dropbox\Beyond_GDP\BRA\BRA_03_exp.txt", wide  noquote replace
