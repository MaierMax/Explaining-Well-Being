clear all

*cd "C:\Zach\Projects_Pete\Beyond GDP\RUS\Raw Data\Household and Individual 1998 (R8)"
cd "C:\Users\Rui\Dropbox\Beyond_GDP\RUS\Raw Data\Household and Individual 1998 (R8)"
** Collecting Adult Data **
use "r8inwork.906.dta",clear
drop if inmover8 == 1
gen age = i8intyer -  i8birthy + 1
drop if age <=0
drop if age >100
drop if age == .

replace  i8pwrkwh = 0 if  i8pwrkwh ==.
replace i8owrkwh = 0 if i8owrkwh ==.

gen hours =  i8pwrkwh + i8owrkwh
replace hours = 0 if hours ==.
replace hours = 0 if age < 16
** Russian works really long time per year!!
**gen hrs = hours * 51
gen hrs = hours * 44.9

label var hrs "total worked hours per week"
gen leisure = (5840 - hrs)/5840
drop if leisure <= 0
drop if leisure > 1
label var leisure "the proportion of total hours in a year that a person does not work"
keep  site8  censusd8  family8  person8 leisure age
rename person8 pcode
save "RUS_98_adlt.dta",replace

** Coleecting Children Data **
use "r8inchld.906.dta", clear
gen age =  i8intyer -  i8birthy + 1
drop if age <=0
drop if age >100
drop if age == .
* Assuming no working hours for kids
gen leisure =1
label var leisure "the proportion of total hours in a year that a person does not work"
keep site8 censusd8  family8  person8 leisure age
rename person8 pcode
save "RUS_98_child.dta",replace

use "RUS_98_adlt.dta",clear
app using "RUS_98_child.dta"
sort site8 censusd8  family8 pcode
save "RUS_98_pl.dta",replace

** Collecting Household Data ****
use "r8hhrost.906.dta",clear
rename  hhwgt_8 wt
rename did hhid
drop if  hhmover8 ==1

merge m:m site8 censusd8 family8 using "r8heexpd.906.dta"
drop if _merge ==1
drop if _merge ==2
drop _merge 
replace  totexpn8 = 0 if  totexpn8 ==.
replace durabn8 = 0 if durabn8 ==.
gen hhexp =  totexpn8 - durabn8
drop if hhexp <=0
drop if hhexp ==.
keep site8 censusd8 family8 hhid wt hhexp
save "RUS_98_hh.dta",replace

merge m:m site8 censusd8 family8 using "r8heincm.906.dta"
drop if _merge ==2
drop _merge 

rename  tincm_n8 hhinc
drop if hhinc <=0
drop if hhinc ==.
keep site8 censusd8 family8 hhid hhexp hhinc wt
sort site8 censusd8 family8 
save "RUS_98_hh.dta",replace

merge m:m site8 censusd8 family8 using "r8hecats.906.dta"
drop if _merge ==2
drop _merge
gen hhsize =  ncat1_8 +ncat2_8 +ncat3_8 +ncat4_8+ ncat5_8 +ncat6_8
keep site8 censusd8 family8 hhid hhexp hhinc hhsize wt
sort site8 censusd8 family8
save "RUS_98_hh.dta",replace

merge m:m site8 censusd8 family8 using "RUS_98_pl.dta" 
drop if _merge == 1
drop if _merge == 2
drop _merge
sort hhid pcode

summ wt
gen weight = wt/r(sum)
lab var weight "Normalized Weight"

keep hhid age hhsize hhexp leisure weight
order  hhid hhsize age hhexp leisure weight
sort hhid
save "C:\Users\Rui\Dropbox\Beyond_GDP\RUS\Calculation\RUS_98.dta",replace
format weight %11.4e
outfile using "C:\Users\Rui\Dropbox\Beyond_GDP\RUS\RUS_98.txt", replace wide


