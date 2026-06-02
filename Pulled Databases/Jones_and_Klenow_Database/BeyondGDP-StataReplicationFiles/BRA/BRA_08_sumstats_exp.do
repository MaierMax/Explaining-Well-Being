clear all
*cd "C:\Zach\Projects_Pete\Brazil\POF\Data_0809\Raw_Dic\output"
cd "C:\Users\Rui\Dropbox\Beyond_GDP\BRA\Raw Data\Raw Data\POF\Data_0809\Raw_Dic\output"

use "reg1.dta"
drop if QTD_UC ~=1

merge 1:m iddom using "reg2.dta"
drop _merge

drop if NUM_UC ~=1
* keep the household where the consumption unit equals 1 (keeping more than 99.8% data)

********************Rui *******************
*calculate hhsize by number of observations in each family
sort iddom
by iddom: gen hhsize=_N  
********************end edit **************

drop if IDADE_ANOS ==.
* There are a bunch of zeros in age, which means new-borns are treated age=0
gen age = IDADE_ANOS +1
drop if age <= 0 
drop if age > 100

*test: hhsize and hhsize_data are perfect match! 
rename QTD_MORADOR_DOMC hhsize_data
gen diff = hhsize - hhsize_data
tab diff
*drop if hhsize ==.

* transfer monthly income to annual income
gen hhinc = RENDA_TOTAL*12
drop if hhinc <=0

keep iddom FATOR_EXPANSAO2 age hhsize hhinc
save "Brazil_09_exp_raw.dta", replace

* Including Expenditure Code 18 
use "reg8.dta"
drop if NUM_UC ~=1
keep if NUM_QUADRO == 18
by iddom, sort: egen exp_18 = sum(VALOR_ANUAL_EXPANDIDO2/FATOR_EXPANSAO2) 
label var exp_18 "annualized value of expenditure code 18"
keep iddom exp_18
* Delete the duplicates
sort iddom
duplicates drop iddom, force

merge 1:m iddom using "Brazil_09_exp_raw.dta"
drop _merge
save "Brazil_09_exp_raw.dta", replace

* Including Expenditure Code 22 - 50, excluding 48
use "reg12.dta"
drop if NUM_QUADRO == 48
drop if NUM_UC ~=1
by iddom, sort: egen exp_22_50 = sum(VALOR_ANUAL_EXPANDIDO2/FATOR_EXPANSAO2) 
label var exp_22_50 "annualized value of expenditure code 22-50"
keep iddom exp_22_50
* Delete the duplicates
sort iddom
duplicates drop iddom, force

merge 1:m iddom using "Brazil_09_exp_raw.dta"
drop _merge
save "Brazil_09_exp_raw.dta", replace

* Including Expenditure Code 10,12,13
use "reg7.dta"
drop if NUM_QUADRO == 11
drop if NUM_UC ~=1
by iddom, sort: egen exp_10_13 = sum(VALOR_ANUAL_EXPANDIDO2/FATOR_EXPANSAO2) 
label var exp_10_13 "annualized value of expenditure code 10, 12, 13"
keep iddom exp_10_13
* Delete the duplicates
sort iddom
duplicates drop iddom, force

merge 1:m iddom using "Brazil_09_exp_raw.dta"
drop _merge
save "Brazil_09_exp_raw.dta", replace

* Including Expenditure Code 6, 7
use "reg6.dta"
drop if NUM_QUADRO == 8
drop if NUM_QUADRO == 9
drop if NUM_UC ~=1
by iddom, sort: egen exp_6_7 = sum(VALOR_ANUAL_EXPANDIDO2/FATOR_EXPANSAO2) 
label var exp_6_7 "annualized value of expenditure code 6, 7"
keep iddom exp_6_7
* Delete the duplicates
sort iddom
duplicates drop iddom, force

merge 1:m iddom using "Brazil_09_exp_raw.dta"
drop _merge
save "Brazil_09_exp_raw.dta", replace

* Including Expenditure Code 19
use "reg9.dta"
by iddom, sort: egen exp_19 = sum(VALOR_ANUAL_EXPANDIDO2/FATOR_EXPANSAO2) 
label var exp_19 "annualized value of expenditure code 19"
drop if NUM_UC ~=1
keep iddom exp_19
* Delete the duplicates
sort iddom
duplicates drop iddom, force

merge 1:m iddom using "Brazil_09_exp_raw.dta"
drop _merge
save "Brazil_09_exp_raw.dta", replace

* Including Expenditure Code 10
use "reg10.dta"
by iddom, sort: egen exp_10 = sum(VALOR_ANUAL_EXPANDIDO2/FATOR_EXPANSAO2) 
label var exp_10 "annualized value of expenditure code 10- Code 9001"
drop if NUM_UC ~=1
keep iddom exp_10
* Delete the duplicates
sort iddom
duplicates drop iddom, force

merge 1:m iddom using "Brazil_09_exp_raw.dta"
drop _merge
save "Brazil_09_exp_raw.dta", replace

replace exp_18 = 0 if exp_18 ==.
replace exp_22_50 = 0 if exp_22_50 ==.
replace exp_10_13 = 0 if exp_10_13 ==.
replace exp_6_7 = 0 if exp_6_7 ==.
replace exp_19 = 0 if exp_19 ==.
replace exp_10 = 0 if exp_10 ==.


gen hhexp = exp_18 + exp_22_50 + exp_10_13 + exp_6_7 + exp_19 + exp_10
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

summ FATOR_EXPANSAO2
gen weight=FATOR_EXPANSAO2/r(sum)
lab var weight "Normalized Individual Weight"

keep hhid hhsize age hhexp weight
order hhid hhsize age hhexp weight
save "C:\Users\Rui\Dropbox\Beyond_GDP\BRA\Calculation\BRA_08_exp.dta", replace
format weight %11.4e
outfile using "C:\Users\Rui\Dropbox\Beyond_GDP\BRA\BRA_08_exp.txt", wide noquote replace
