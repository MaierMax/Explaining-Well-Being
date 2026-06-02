**************************************************************
** Estimating theta from the FOC for 25-55 year old WORKERS **
**************************************************************

clear all
local working_dir = "/Users/xurui/Dropbox/Beyond_GDP/FRA"
*local working_dir = "C:\Users\Rui\Dropbox\Beyond_GDP\FRA"
set mem 100m
set more off
*************************************************************
* CREATE VARIABLE EXPENDITURES  ***************
*************************************************************

**OPEN MAIN DIRECTORY*
***********************************************************
cd `working_dir'
***********************************************************
use `working_dir'/2005/c05d.dta

*log using FRA_05_sumstats.log, replace

**tot_exp_wd means total expenditures with durables and this is just to make sure that we are understading the way they construct expenditures**
egen tot_exp_wd=  rowtotal(c01* c02* c03* c04* c05* c06* c07* c08* c09* c10* c11* c12*)

*************************************************************
*ctotale is total expenditures constructed in the french database*
*************************************************************

*gen dif_exp= (tot_exp_wd - ctotale)/ ctotale

***verify the construction of the variable total expenditures**
 
 *sum dif_exp, detail
 
 **************************************************************
 ****Generate expenditures without durables*******************
 *************************************************************
 
 
egen fr_exp_01 = rowtotal(c01* c02* c03* c04* c054* c056* c06* c073* c08111 c08131 c09121  c09321 c09331 c094* c095* c096*  c10*  c11*  c12* ) 

** [AIM change: corrected some categories. one (irrelevant) doubt: are books leisure durables?] *****************
egen fr_exp_aim_add = rowtotal(c07241 c07242 c09711)
egen fr_exp_aim_rem = rowtotal(c03312 c04311 c04321 c04611 c06412 c09121 c09431 c09511 c10152 c11132 c12612) 
egen fr_exp_rent    = rowtotal(c04111 c04121) 

replace fr_exp_01 = fr_exp_01 + fr_exp_aim_add - fr_exp_aim_rem - fr_exp_rent
** [end AIM change] *********************************************************************************************
 
keep fr_exp_01 ident_men tot_exp_wd

rename ident_men hhid

sort hhid

save `working_dir'/2005/expenditures_FRA_05.dta, replace


clear
**************************************************************************************************************************************************************************************



*cd "C:\Documents and Settings\Pete Klenow\My Documents\My Documents\Rawls\MEX"


use `working_dir'/2005/individu.dta, clear

*use "C:/Documents and Settings/Pete Klenow/My Documents/Rawls Micro Datasets/France/2006/individu.dta", clear
destring lienpref, replace
destring noi, replace
* Drop all non-residents in HH (In the ENIGH -Mexican Data- Everyone is a resident)
* Drop all obs with negative age 
* keep relevant variables: household ID number (ident_men), person code (noi, note there is also ident_ind that is the id of hh plus noi), is person respondent 
* (I think we do not have this), relationship to head (lienpref), age in years (age), 
*  gender (sexe)
**(NOTE) I RENAMED ALL THE VARIABLES WITH THE NAMES THAT YOU PROPOSED IN THIS FILE.

* rename variables: education and cluster number
* sort person code for tied values of Household ID
* Drop all non-residents in HH, all obs with negative age, keep relevant variables, rename vars

rename ident_men hhid
sort hhid
** [Rui: calculate hhsize before dropping any observation ]
by hhid: gen hhsize=_N
lab var hhsize "Household Size"

** [AIM change below: stopped dropping age==0 people, and added 1 to ages for correct mapping onto lamstats code] 
tab age
drop if age < 0  
drop if age >= 100
replace age = age + 1

*I missed the variable cluseter and the variable who identifies the respondent
qui {
keep hhid noi lienpref age sexe hhsize rev100_d rev200_d rev201_d
rename noi pcode 
rename lienpref rel_head
rename sexe gender
rename rev100_d income_exsalary
rename rev200_d salary
rename rev201_d secondary
sort hhid pcode
}
gen earning = (salary + secondary)/12
replace salary = salary/12
* Create hhsize variable (Household Size) determined by number of observations for each Household ID
**(NOTE) IN ANOTHER FILE THERE IS ALSO THE SIZE OF THE HOUSE AND TOTAL RESIDENTS.
qui {
*by hhid: gen hhsize=_N
*lab var hhid "Household Size"
order hhid pcode hhsize age gender salary earning
sort hhid
save `working_dir'/FRA_05.dta, replace
}

**(NOTE) THE FILE menage84.dta HAS THE WEIGHTS VARIBLES 
*Bring in weights
use `working_dir'/2005/depmen.dta, clear


rename ident_men hhid
rename pondmen rcweight


sort hhid
keep hhid rcweight 
merge 1:m hhid using `working_dir'/FRA_05.dta
**(NOTE) SHOULD I DROP EVERYTHING ELSE EXCEPT FOR THE WEIGHTS
*drop _m lang_ type metro prov newprov sweight

sort hhid pcode hhsize
drop _merge
save `working_dir'/FRA_05.dta, replace


**(NOTE) TOTAL EXPENDITURES IN THE ORIGINAL FILE DOES NOT INCLUDE SAVINGS;
**(NOTE) BRING IN CONSTRUCTED HH EXPENDITURE (fr_exp_01), DEFINED AS [TOTAL MONTHLY EXPENDITURE]-[DURABLES]
**(NOTE) GASTOT (MONTHLY EXPENDITURE) IS A NORMALIZED VARIABLE THAT CAPTURES MONTHLY, EXPENDITURES MADE IN THE LAST 3 MONTHS AND EXPENDITURES MADE IN THE LAST 6 MONTHS

* Open constructed HH monthly expenditure
qui {
use `working_dir'/2005/expenditures_FRA_05.dta, clear

gen hhexp= fr_exp_01/12

* hhexp includes: housing, utilities, food, clothing, health care, insurance, 
*                 schooling, child care, transportation
* hhexp excludes: savings, remittances, durables


lab var hhexp "HH Total Monthly Expenditure"


keep hhid hhexp
sort hhid
merge 1:m hhid using `working_dir'/FRA_05.dta

order hhid pcode hhsize age hhexp rcweight  salary earning
sort hhid pcode
drop _merge
keep if pcode~=.
save `working_dir'/FRA_05.dta, replace
}


*bring in income for comparison
*Open constructed HH monthly income
*hhinc includes: rent  income, remittances, regular wage income, 
*	first casual income, second casual income,  agricultural  income, 
*	self-employment income, housing/food support if needed
qui {
use `working_dir'/2005/menage.dta,  clear

**revtot- annual household income from all sources except for exceptional resources**
**revexc- annual income from exceptional resources- hazard games, donations, inheritance, etc**;
rename ident_men hhid
gen hhinc= (revtot + revexc)/12

keep hhid hhinc
sort hhid
merge 1:m hhid using `working_dir'/FRA_05.dta
order hhid pcode hhsize age hhexp hhinc rcweight
sort hhid pcode
drop _merge
keep if pcode~=.
save `working_dir'/FRA_05.dta, replace
}

**Compute monthly noividual hrs worked from weekly hours worked  
quietly {
use `working_dir'/2005/individu.dta, clear

***********************************************
**Variables: **********************************
**heurex- amount of time working or studying***
**occ= "10" is working and currently employed**
***********************************************
destring noi, replace
rename ident_men hhid
rename noi pcode

gen hours_wo= tpstra
keep hhid pcode hours_wo 
*gen mohours=hours_wo*(52/12) //changed to monthly hours worked = weekly hours worked*(52/12), from weekly hours worked*(4.5)
lab var hours_wo "Weekly Hours Worked"

sort hhid pcode
merge 1:1 hhid pcode using `working_dir'/FRA_05.dta
drop _merge
}
* drop negative labor hours (118 dropped) AIM: No, 0 dropped!
drop if hours_wo<0 
* drop obs with missing expenditures values  AIM: 1 dropped 
drop if hhexp==. 
* drop obs with missing income values 
drop if hhinc==. 

**(NOTE) I WILL DROP ALSO NEGATIVE INCOME
drop if hhinc<0


quietly {
sort hhid pcode
gen hrs_week=0
replace hrs_week=hours_wo if hours_wo<.
}
*drop extreme values exceeding maximum available monthly working hrs -AIM: 0 of these, and in any case why not just censor at 7*16, instead of dropping
drop if hrs_week>=(7*16) 
quietly {
gen leisure=1-((41.0*hrs_week)/(365*16))
 
gen wave=2000
lab var leisure "Total Annual Leisure Hours"
* there are 3 obs with hhinc<0, make sure to drop them when want log income later

**(NOTE) I DROPPED IN THE ORDERING PERS_RES WHICH I DON'T KNOW WHAT IT MEANS
order hhid pcode wave hhsize age hhexp  salary earning hhinc leisure rcweight  rel_head hrs_week 

sort hhid pcode wave
save `working_dir'/FRA_05.dta, replace
}


svyset [pweight=rcweight]
svy: mean hhsize age hhexp hhinc leisure

*normalize weights to sum to 1
summ rcweight
gen weight=rcweight/r(sum)
lab var weight "Normalized noividual Weight"
destring hhid,ignore(" ") replace
format hhid %30.0f
keep hhid hhsize age  hhexp hhinc salary earning leisure weight 
order hhid hhsize age  hhexp hhinc salary earning leisure weight
save `working_dir'/FRA_05_earning.dta, replace

keep hhid hhsize age hhexp leisure weight 
order hhid hhsize age hhexp leisure weight
save `working_dir'/FRA_05.dta, replace

describe
summarize


***** outsheet hhid pcode age hhexp leisure weight using MEX_00.csv , comma replace
format weight %11.4e
outfile using `working_dir'/FRA_05.txt , wide replace


*log close
*exit

**(NOTE ABOUT VARIABLES)
**household ID number =(ident_men)
** person code= (noi)
** relationship to head=(lienpref)
** age in years =(age)
