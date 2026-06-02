clear all

*cd "C:\Zach\Projects_Pete\Beyond GDP\RUS\Raw Data\Household and Individual 2007 (R16)"
cd "C:\Users\Rui\Dropbox\Beyond_GDP\RUS\Raw Data\Household and Individual 2007 (R16)"
** Collecting Adult Data **
use "rpinadlt.dta",clear
drop if inmoverp == 1
gen age =  ipintyer -  ipbirthy + 1
drop if age <=0
drop if age >100
drop if age == .

replace  ippwrkwh = 0 if  ippwrkwh ==.
replace ipowrkwh = 0 if ipowrkwh ==.

gen hours =  ippwrkwh + ipowrkwh
replace hours = 0 if hours ==.
replace hours = 0 if age < 16
** Russian works really long time per year!!
**gen hrs = hours * 51
gen hrs = hours * 44.4

label var hrs "total worked hours per week"
gen leisure = (5840 - hrs)/5840
drop if leisure <= 0
drop if leisure > 1
label var leisure "the proportion of total hours in a year that a person does not work"
keep sitep censusdp familyp personp leisure age
rename personp pcode
save "RUS_07_adlt.dta",replace

** Coleecting Children Data **
use "rpinchld.dta", clear
gen age =  ipintyer - ipbirthy + 1
drop if age <=0
drop if age >100
drop if age == .
* Assuming no working hours for kids
gen leisure =1
label var leisure "the proportion of total hours in a year that a person does not work"
keep sitep censusdp familyp personp leisure age
rename personp pcode
save "RUS_07_child.dta",replace

use "RUS_07_adlt.dta",clear
app using "RUS_07_child.dta"
sort sitep censusdp familyp pcode
save "RUS_07_pl.dta",replace

** Collecting Household Data ****
use "rphh3.dta",clear
rename  hhwgt_p wt
rename lid hhid
drop if  hhmoverp ==1

merge m:m sitep censusdp familyp using "rpheexpd_2.dta"
drop if _merge ==1
drop if _merge ==2
drop _merge 
replace  totexpnp = 0 if  totexpnp ==.
replace  durabnp = 0 if  durabnp ==.
gen hhexp =  totexpnp -  durabnp
drop if hhexp <=0
drop if hhexp ==.
keep sitep censusdp familyp hhid wt hhexp
save "RUS_07_hh.dta",replace

merge m:m sitep censusdp familyp using "rpheincm_2.dta"
drop if _merge ==2
drop _merge 
rename tincm_np hhinc
drop if hhinc <=0
drop if hhinc ==.
keep sitep censusdp familyp hhid hhexp hhinc wt
sort sitep censusdp familyp
save "RUS_07_hh.dta",replace

merge m:m sitep censusdp familyp using "rphecats_2.dta"
drop if _merge ==2
drop _merge
gen hhsize =  ncat1_p + ncat2_p +ncat3_p +ncat4_p +ncat5_p+ ncat6_p
keep sitep censusdp familyp hhid hhexp hhinc hhsize wt
sort sitep censusdp familyp
save "RUS_07_hh.dta",replace

merge m:m sitep censusdp familyp using "RUS_07_pl.dta" 
drop if _merge == 2
drop _merge
sort hhid pcode

summ wt
gen weight = wt/r(sum)
lab var weight "Normalized Weight"

keep hhid hhsize age hhexp leisure weight
order hhid hhsize age hhexp leisure weight
sort hhid
save "C:\Users\Rui\Dropbox\Beyond_GDP\RUS\Calculation\RUS_07.dta",replace
format weight %11.4e
outfile using "C:\Users\Rui\Dropbox\Beyond_GDP\RUS\RUS_07.txt",replace wide


