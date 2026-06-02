********************************************************
**PROGRAM 1: GENERATING COUNTRY DATASET FRANCE_1984.DTA**
********************************************************

clear all
*local working_dir = "C:\research\ra_pk\rawls\FRA"
local working_dir = "C:\Users\Rui\Dropbox\Beyond_GDP\FRA"
set mem 100m
*************************************************************
* CREATE VARIABLE EXPENDITURES  ***************
*************************************************************

**OPEN MAIN DIRECTORY*
***********************************************************
cd `working_dir'
***********************************************************


*log using FRA_84_sumstats.log, replace


************************************************************
* [AIM]: construct sum(depen94.dta) expenditures
************************************************************
use 1984\depen84.dta, clear
* Note: amounts in this file are expressed in cents. Must divide by 100 for comparability
destring chif84, generate(chif84_n)

* 1. Exceptions:
* 1.1 A household with miscoded, undeclared income tax (>90% spending is income tax, with value = 3*"missing value code")
* replace dep0277  = . if dep0277==299999700

* 2. Construct groupings
replace dep0277 		= dep0277/100
replace dep0277e 		= dep0277e/100

gen d_home_improvement  = dep0277 if (chif84=="3123" | (chif84_n>=3200 & chif84_n<=3370))
gen d_tax_property_etc 	= dep0277 if (chif84=="3500" | chif84=="3501"  | chif84=="3111" | chif84=="3120" | chif84=="3121" )
gen d_home_durables		= dep0277 if (chif84_n>=4000 & chif84_n<=4110) | (chif84_n>=4300 & chif84_n<=4331)
gen d_auto       		= dep0277 if (chif84=="6100" |  chif84=="6101")
gen d_2wheel     		= dep0277 if (chif84=="6110" | chif84=="6111"  | chif84=="6112" | chif84=="6113")
gen d_auto_tax    		= dep0277 if (chif84=="6620" |  chif84=="6621")
gen d_leisure_durables	= dep0277 if (chif84_n>=7100 & chif84_n<=7304) | (chif84_n>=7600  & chif84_n<=7623)
gen d_transfers			= dep0277 if (chif84_n>=8100 & chif84_n<=8105) | (chif84_n>=8107 & chif84_n<=8108)
gen d_property_purchase = dep0277 if chif84=="8115"
gen d_tax_income  		= dep0277 if chif84=="8210"
gen d_tax_land    		= dep0277 if chif84=="8220"

* Due to the lack of estimates for imputed rent for owned housing, we are netting rent.
gen d_rent				= dep0277 if chif84=="3100" | chif84=="3103" | chif84=="3110"

collapse (sum) dep0277 d_*, by(mena)
sort mena
save 1984\exp_depen84.dta, replace

* Notes: dep0277 and dep0277e are under different classifications of goods.
* At the hh sum level, dep0277 is larger than dep0277 in 3367 of 11976 cases. 
* But difference is at most 16 francs.
* [end AIM] ************************************************


************************************************************
* [AIM]: construct expenditures from group files
* This section was in the previous code, but was completely changed
* Expenditures are from the following years:
* autos       : 1984 mostly, also some 1983 and 1985
* 2roux       : same
* gros achats : same, plus 10 "unknown year"
* biens du    : same, with 10 "unknown year"
************************************************************
use 1984\menage84.dta, clear
keep mena deptot ponder revtot mimpo monmob mliv1 mliv2 dette0 maidf monmob
sort mena
replace deptot = deptot/100
format deptot %12.2f
*drop if deptot==0
save 1984\exp_deptot.dta, replace

use 1984\automo84.dta, clear
keep if prixvoi>0 & prixvoi!=999999
collapse (sum) exp_auto = prixvoi, by(mena)
sort mena
save 1984\exp_automo84.dta, replace

use 1984\dxroux84.dta, clear
keep if prix2r>0 & prix2r!=999999
collapse (sum) exp_2r = prix2r, by(mena)
sort mena
save 1984\exp_dxroux84.dta, replace

use 1984\grosach.dta, clear
keep if prix22>0 & prix22!=99999
collapse (sum) exp_22 = prix22, by(mena)
sort mena
save 1984\exp_grosach.dta, replace

use 1984\biensdu.dta, clear
keep if prix24>0 & prix24!=99999
collapse (sum) exp_24 = prix24, by(mena)
sort mena
save 1984\exp_biensdu.dta, replace

use 1984\autresa.dta, clear
keep if prix26>0 & prix26!=99999
collapse (sum) exp_26 = prix26, by(mena)
sort mena
save 1984\exp_autresa.dta, replace

use 1984\gtravim.dta, clear
keep if deptrav>0 & deptrav!=99999
collapse (sum) exp_deptrav = deptrav, by(mena)
sort mena
save 1984\exp_gtravim.dta, replace


* Merge them all onto expenditures file
use 1984\exp_deptot.dta, clear
foreach s in automo84 dxroux84 grosach biensdu autresa gtravim depen84 {
merge 1:1 mena using 1984\exp_`s'.dta
assert _merge!=2
drop _merge
}
mvencode exp_* , mv(0)

* Recoding
foreach a in mimpo maidf monmob mliv1 mliv2 {
	replace `a' = 0 if (`a'==999 | `a'==9999 | `a'==99999 | `a'==999999 )
}


*  * Consumption measures net of non-durables, and transfer payments
*  * Approach 1. Just use deptot (net of nothing)
*  gen fr_exp_84_1 = deptot

*  * Approach 2. Variable from total file (deptot), minus identified quantities from auxiliary expenditure files.
*  * Whenever a category of spending is referenced in the main aggregate expenditure file, or in an auxiliary expenditure file, deduct it from deptot.  
*  gen fr_exp_84_2 = deptot - exp_auto - exp_2r - exp_22 - exp_24 - exp_26 - exp_deptrav - mliv1 - mliv2 - mimpo - dette0 - maidf - monmob
*  replace fr_exp_84_2 = . if fr_exp_84_2 < 0

*  * Approach 3. Variable from total file (deptot), minus identified quantities from auxiliary expenditure files.
*  * Use my intuition as to whether categories are actually included in deptot, and thus need subtracting.
*  gen fr_exp_84_3 = deptot - exp_auto - exp_2r - exp_22 - exp_24 - exp_26 - exp_deptrav

*  * Approach 4. Sum of all disaggregate expenditures (excluding categories to be netted) from micro expenditures file (depense84.dta)
gen fr_exp_84_4 = dep0277 - d_home_improvement - d_tax_property_etc - d_home_durables - d_auto - d_2wheel - d_auto_tax - d_leisure_durables - d_transfers - d_property_purchase - d_tax_income - d_tax_land - d_rent
ren fr_exp_84_4 fr_exp_84

gen fr_exp_84_plus_rent = fr_exp_84 + d_rent
keep mena fr_exp_84 fr_exp_84_plus_rent

format fr_exp_84 %12.2f 
save 1984\expenditures_fr_84.dta, replace

*** [end AIM] ***********************************************************



clear
************************************************************************************************
* [AIM]: The variable "age" in the mena.dta file is defined as year of birth minus 1984.
* To make this equal to 2005 data, I am reconstructing this variable to be equal to
* "age at time of interview". Presumably more compatible with interpretation of survey data 
* as a single snapshot in time.
************************************************************************************************
use 1984\c1.dta, clear
destring indi, replace
contract mena indi date72
drop _freq

sort mena indi
gen interview_date = date(date72,"DM19Y")
format  interview_date %td
keep mena indi interview_date
sort mena indi
save 1984\interview_dates.dta, replace

* [end AIM} **************************************************************************************


use 1984\indvi84.dta, clear
destring lien, replace
destring indi, replace
*** [Rui: *create hhsize before dropping any observation]
sort mena
by mena: gen hhsize=_N
lab var hhsize "Household Size"

* Drop all non-residents in HH
* Drop all obs with negative age 
* keep relevant variables: household ID number (mena), person code (indi), is person respondent 
* (I think we do not have this), relationship to head (lien), age in years (age), 
*  gender (sexe)
**(NOTE) I RENAMED ALL THE VARIABLES WITH THE NAMES THAT YOU PROPOSED IN THIS FILE.

* rename variables: education and cluster number
* sort person code for tied values of Household ID
* Drop all non-residents in HH, all obs with negative age, keep relevant variables, rename vars


** [AIM change: corrected ages to "rounded down", i.e. common use in English language]. ***********
** [Note: ages were previously defined as: year of birth - 1984]
merge 1:1 mena indi using 1984\interview_dates.dta
drop _merge
by mena: egen earliest_interview = min(interview_date)
replace interview_date = earliest_interview if interview_date==.

gen dob = date(journais,"DMY")
format dob %td

gen age_at_interview = round((interview_date - dob)/365.25,1)
replace age_at_interview = 0   if age_at_interview==-1 & age==0
* preceding line: one observation where interview date was clearly miscoded
replace age_at_interview = age if age_at_interview==.
* 124 of these are due to some missing month or day of birth, 3 due to missing interview date
drop age
ren age_at_interview age

drop if age < 0 
drop if age >= 100
replace age = age + 1
* [end AIM change] **********************************************************************************



*I missed the variable cluseter and the variable who identifies the respondent
qui {
keep mena indi lien age sexe hhsize
rename mena hhid
rename indi pcode
rename lien rel_head
rename sexe gender
sort hhid pcode
}


qui {
*by hhid: gen hhsize=_N
*lab var hhid "Household Size"
order hhid pcode hhsize age gender
sort hhid
save FRA_84.dta, replace
}

**(NOTE) THE FILE menage84.dta HAS THE WEIGHTS VARIBLES 
*Bring in weights
use 1984\menage84.dta, clear


rename mena hhid
rename ponder rcweight


sort hhid
keep hhid rcweight 
merge 1:m hhid using FRA_84.dta
* AIM: 3 hhid not merged: 932493214582004039321 831183504968043148354 240524602350036044255

*merge 1:m hhid using "E:\4th Year\KLENOW_RA\france\FRA_84.dta"
**(NOTE) SHOULD I DROP EVERYTHING ELSE EXCEPT FOR THE WEIGHTS
*drop _m lang_ type metro prov newprov sweight

sort hhid pcode hhsize
drop _merge
save FRA_84.dta, replace


**(NOTE) TOTAL EXPENDITURES IN THE ORIGINAL FILE DOES NOT INCLUDE SAVINGS;
**(NOTE) BRING IN CONSTRUCTED HH EXPENDITURE (fr_exp_84), DEFINED AS [TOTAL MONTHLY EXPENDITURE]-[DURABLES]
**(NOTE) GASTOT (MONTHLY EXPENDITURE) IS A NORMALIZED VARIABLE THAT CAPTURES MONTHLY, EXPENDITURES MADE IN THE LAST 3 MONTHS AND EXPENDITURES MADE IN THE LAST 6 MONTHS

* Open constructed HH monthly expenditure
qui {
use 1984\expenditures_fr_84.dta, clear
*use expenditures_fr_84.dta, clear


rename  mena hhid
gen hhexp=  fr_exp_84/12



* hhexp includes: housing, utilities, food, clothing, health care, insurance, 
*                 schooling, child care, transportation
* hhexp excludes: savings, remittances, durables



lab var hhexp "HH Total Monthly Expenditure"

keep hhid hhexp 
sort hhid
merge 1:m hhid using FRA_84.dta

order hhid pcode hhsize age hhexp rcweight 
sort hhid pcode
drop _merge
keep if pcode~=.
save FRA_84.dta, replace
}


*bring in income for comparison
*Open constructed HH monthly income
*hhinc includes: rent  income, remittances, regular wage income, 
*	first casual income, second casual income,  agricultural  income, 
*	self-employment income, housing/food support if needed
qui {
use 1984\menage84.dta, clear


rename mena hhid
gen hhinc= revtot/12

keep hhid hhinc
sort hhid
merge 1:m hhid using FRA_84.dta
*merge 1:m hhid using "E:\4th Year\KLENOW_RA\france\FRA_84.dta"
*order hhid pcode hhsize age gender hhinc hhexp
order hhid pcode hhsize age hhexp hhinc rcweight
sort hhid pcode
drop _merge
keep if pcode~=.
save FRA_84.dta, replace
}

**Compute monthly individual hrs worked from weekly hours worked  
quietly {
use 1984\indvi84.dta, clear

***********************************************
**Variables: **********************************
**heurex- amount of time working or studying***
**occ= "10" is working and currently employed**
***********************************************
destring indi, replace
rename mena hhid
rename indi pcode

gen hours_wo= heurex if occ=="10"
keep hhid pcode hours_wo 
*gen mohours=hours_wo*(52/12) //changed to monthly hours worked = weekly hours worked*(52/12), from weekly hours worked*(4.5)
lab var hours_wo "Weekly Hours Worked"

sort hhid pcode
merge hhid pcode using FRA_84.dta
drop _merge
}
* drop negative labor hours (118 dropped)
drop if hours_wo<0
*drop obs with missing expenditures values  
drop if hhexp==. 
*drop obs with missing income values 
drop if hhinc==.

**(NOTE) I WILL DROP ALSO NEGATIVE INCOME
drop if hhinc<0


quietly {
sort hhid pcode
gen hrs_week=0
replace hrs_week=hours_wo if hours_wo<.
}
* drop extreme values exceeding maximum available monthly working hrs
drop if hrs_week>=(7*16) 
quietly {
gen leisure=1-((43.5*hrs_week)/(365*16))
 
gen wave=2000
lab var leisure "Total Annual Leisure Hours"
* there are 3 obs with hhinc<0, make sure to drop them when want log income later

**(NOTE) I DROPPED IN THE ORDERING PERS_RES WHICH I DON'T KNOW WHAT IT MEANS
order hhid pcode wave hhsize age hhexp hhinc leisure rcweight  rel_head hrs_week 

sort hhid pcode wave
save FRA_84.dta, replace
}


svyset [pweight=rcweight]
svy: mean hhsize age hhexp hhinc leisure


*normalize weights to sum to 1
sum rcweight
gen weight=rcweight/r(sum)
lab var weight "Normalized Individual Weight"
destring hhid,ignore(" ") replace
format hhid %30.0f
/*
gen hhid_1 = substr(hhid,1,11)
gen hhid_2 = substr(hhid,-9,9)
egen hhid_new = concat(hhid_1 hhid_2)
*destring hhid_new, gen(hhid_tot) float
*format hhid_new %20.0f
drop hhid
rename hhid_new hhid
*/
keep hhid hhsize age hhexp  leisure weight
order hhid hhsize age hhexp leisure weight
*destring hhid,replace
*format hhid %20.0f
sort hhid age 

save "FRA_84.dta", replace

describe
summarize
format weight %11.4e
outfile using "FRA_84.txt" , wide replace

*log close
*exit

**(NOTE ABOUT VARIABLES)
**household ID number =(mena)
** person code= (indi)
** relationship to head=(lien)
** age in years =(age)


* [aim] Impact of corrections (age, consumer durables, etc) on Lorenz curves
*	use FRA_84.dta, clear
*	ren hhexp hhexp_new
*	merge 1:1 hhid  pcode using FRA_84_gabi.dta , keepusing(hhexp)
*	ren hhexp hhexp_old
*
*	foreach c in new old {
*		glcurve hhexp_`c' [aw=weight] if _merge==3, gl(gl_`c') p(support_`c') nograph
*		sum gl_`c'
*		replace gl_`c' = gl_`c'/r(max)
*	}
*
*	graph twoway (line gl_old support_old, lwidth(vvthin)  sort) (line gl_new support_new, lwidth(vvthin)  sort)
*	drop gl* supp*
