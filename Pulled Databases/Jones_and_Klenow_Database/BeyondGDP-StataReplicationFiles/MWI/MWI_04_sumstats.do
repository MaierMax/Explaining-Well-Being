/*
Creates dataset MWI_04.dta with the following common set
of variables for each individual covered in the Malawi IHS2 household survey:
• hhid (household id code)
• hhsize (number of individuals in the household)
• age (age of the individual)
• hhexp (total household expenditures on nondurables and services)
• leisure (fraction of the time endowment the individual is not working)
• weight (sampling weight)
Also includes an individual id for each household
*/


cap log close

set more 1

clear

set mem 2g

cd "C:\Users\Rui\Dropbox\Beyond_GDP\MWI"
log using "MWI_04_sumstats.txt", replace

set linesize 200

/* Bring in HH expenditure constructed by survey agency */
use "ihs2_exp.dta", clear
rename case_id hhid    /* household id */  
rename hhwght weight  /* household weight */
/* compute real annual expenditure excluding major durables */
gen hhexp = 0
foreach var of varlist rexp_cat* {
     drop if `var' == .
     replace hhexp = hhexp + `var'  /* add up expenditures */
}
/* remove major durables */
replace hhexp = hhexp - rexp_cat053 - rexp_cat071 - rexp_cat092
drop if hhexp == .  /* drop missing values */ 
 
qui {				
keep hhid hhsize hhexp weight 
}

expand hhsize  /* replicate household observations for each individual in the household */

gen individid = hhid   /* create individual id */
gen memid = 1		 /* keep track of member number */          
sort hhid

qui{ 
	forvalue id = 1/`=_N' {  /* for each observation */
	     /* create individual id by concatenating hhid with individual number */ 
  		replace individid = individid + string(memid[`id']) if _n == `id'	
		/* assigning member number to each household */	
  		replace memid = memid[`id'] + 1 if _n == `id' + 1 & memid[`id'] < hhsize[`id']
	}

keep hhid individid hhsize hhexp weight

}

save "MWI_04.dta", replace

/* Bring in HH individual age */
use "ihs2_individ.dta", clear
gen individid = case_id + string(memid)
keep individid age 
merge 1:m individid using "MWI_04.dta", keep(match)

qui { 
sort hhid 
order hhid individid hhsize age hhexp weight 
keep hhid individid hhsize age hhexp weight 
}

save "MWI_04.dta", replace

/* Bring in HH individual working hours */
use "sec_e.dta", clear
gen individid = case_id + string(memid)
drop hhid
gen hhid = case_id

gen yrownhrs = 52 * (e08 + e09 + e10)  /* annual hours worked at own business or agriculture */
replace yrownhrs = 0 if yrownhrs == .

gen yremphrs = e22a * e23 * e24  /* annual hours worked as an employee */
replace yremphrs = yremphrs/4 if e22b == 4  /* reported weeks of work in a year instead of a month */
replace yremphrs = 0 if yremphrs == .

gen parttime =  e30 * e11 / 7  /* annual hours on parttime job */
replace parttime = 0 if parttime == .
replace yremphrs = yremphrs + parttime 

gen yrhrs = yremphrs + yrownhrs 

replace yrhrs = 0 if e02 == "X"  /*individuals younger than 5 has 0 hrs */

gen leisure = (5840 - yrhrs)/5840

keep individid leisure

sort individid

merge 1:m individid using "MWI_04.dta", keep(match)

** [Rui: age needs to be adjusted]
replace age = age +1
drop if age < 0 | age ==. | age > 100

*******************end edit ******************************
sort hhid
egen weight_sum = sum(weight)
replace weight = weight/weight_sum
drop if leisure <0
keep hhid hhsize age hhexp leisure weight
order hhid hhsize age hhexp leisure weight

/*
gen pcode = substr(individid,-1,1)
drop individid
destring hhid pcode, replace
*/
save "MWI_04.dta", replace
format weight %11.4e
outfile using "MWI_04.txt" , wide replace noquote
