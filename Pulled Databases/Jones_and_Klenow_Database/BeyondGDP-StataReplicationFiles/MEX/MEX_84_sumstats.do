********************************************************
**PROGRAM 1: GENERATING COUNTRY DATASET MEX_yy.DTA**
* [Note: Year needs to be set in yyyy below. Currently can handle 1984, 2002, 2006]
********************************************************
set more off
clear all
set varabbrev off
set mem 100m
*cd "C:/research/ra_pk/rawls"
*cd "C:/Users/klenow.ECON/Documents/Rawls"
local pete_raw_data_root "C:\Users\Rui\Dropbox\Beyond_GDP\MEX"
local yyyy 1984
local yy = substr("`yyyy'",3,2)

*log using MEX_`yy'_sumstats.log, replace

*use "E:\ENIGH\2002\dbf_02\pobla_2002.dta", clear
use "`pete_raw_data_root'/Mexico/`yyyy'/pobla_`yyyy'.dta", clear
destring edad, replace
*destring folio, replace
*destring num_ren, replace
destring parentesco, replace
destring sexo, replace
*if `yyyy'==2002 | `yyyy'==1984 {
	destring ed_tecnica, replace
	destring ed_formal, replace
	rename ed_formal educ
	rename ed_tecnica educ2
*}
/*else if `yyyy'==2006 {
	destring grado, replace
	destring nivel, replace
	rename grado ed_grade
	rename nivel ed_level
} 
*/
* Drop all non-residents in HH (In the ENIGH -Mexican Data- Everyone is a resident)
* Drop all obs with negative age 
* keep relevant variables: household ID number (folio), person code (num_ren), is person respondent 
* (I think we do not have this), relationship to head (parentesco), age in years (edad), 
* education (ed_formal, ed_tecnica), gender (sexo)
**(NOTE) I RENAMED ALL THE VARIABLES WITH THE NAMES THAT YOU PROPOSED IN THIS FILE.

* rename variables: education and cluster number
* sort person code for tied values of Household ID
* Drop all non-residents in HH, all obs with negative age, keep relevant variables, rename vars

** [Rui: Create hhsize variable (Household Size)]
bysort folio: gen hhsize=_N
lab var hhsize "Household Size"

rename edad age
tab age
drop if age < 0 
drop if age >= 100
replace age = age + 1

*I missed the variable cluseter and the variable who identifies the respondent
qui {
keep folio num_ren parentesco age sexo ed* hhsize
rename folio hhid
rename num_ren pcode
rename parentesco rel_head
rename sexo gender
sort hhid pcode
}

qui {

order hhid pcode hhsize age gender ed*
sort hhid

save "`pete_raw_data_root'/MEX_`yy'.dta", replace
}

**(NOTE) THE FILE HOGAR_2002 HAS THE WEIGHTS VARIBLES 
**(NOTE) ARE WE JUST INTERESTED IN KEEPING THE WEIGHTS?
**(NOTE) I RENAME folio for hhid
*Bring in weights
*use "E:\ENIGH\2002\dbf_02\hogares_2002.dta", clear
use "`pete_raw_data_root'/Mexico/`yyyy'/hogares_`yyyy'.dta", clear
rename folio hhid
rename factor rcweight
/*if `yyyy'==2002 {
	destring tot_resi, replace
	destring tam_hog, replace
	rename tot_resi total_resi
	rename tam_hog size_house
	**(NOTE) I will keep these two variables that are the total number of residentes (total_resi) in order to verify if it is actually the size that you computed before 
	keep hhid rcweight total_resi size_house
}
*/
*else if `yyyy'==1984 {
	destring total_miem, replace
	rename total_miem size_house
	keep hhid rcweight size_house
*}
/*else if `yyyy'==2006 {
	* [aim: I have not doublechecked that residentes is the correct reported variable for hh_size, 
	* but the original code does not even preserve any variable, and it's not used anyway].
	ren residentes size_house
	keep hhid rcweight size_house
}
*/
sort hhid
merge 1:m hhid using "`pete_raw_data_root'/MEX_`yy'.dta"
sort hhid pcode hhsize
drop _merge
save "`pete_raw_data_root'/MEX_`yy'.dta", replace


** Bring in constructed HH expenditure, defined as [Total Monthly Expenditure] - [monthly savings]
**(NOTE) EXPENDITURES IN THE MEXICAN DATA DOES NOT INCLUDE SAVINGS (FOR YEARS 2002 ONWARDS)
**(NOTE) TOTAL EXPENDITURES DOES INCLUDE DURABLES 
**(NOTE) BRING IN CONSTRUCTED HH EXPENDITURE, DEFINED AS [TOTAL MONTHLY EXPENDITURE]-[DURABLES]
**(NOTE) I RENAMED TOTAL MONTHLY EXPENDITURE WHICH WAS GASTOT BY TOTMEXP
**(NOTE) GASTOT (MONTHLY EXPENDITURE) IS A NORMALIZED VARIABLE THAT CAPTURES MONTHLY, EXPENDITURES MADE IN THE LAST 3 MONTHS AND EXPENDITURES MADE IN THE LAST 6 MONTHS

* Open constructed HH monthly expenditure
qui {
*use check_tot_exp_02.dta, clear
use "`pete_raw_data_root'/Mexico/check_tot_exp_`yy'.dta", clear


rename  folio hhid
rename  tot_exp_mine3 hhexp
rename  tot_exp_mine2 hhexp_b


* hhexp includes: housing, utilities, food, clothing, health care, insurance, 
*                 schooling, child care, transportation
* hhexp excludes: savings, remittances, durables



lab var hhexp_b "HH Total Monthly Expenditure including durables"
lab var hhexp "HH Total Monthly Expenditure without durables"
* gen totmexpr1=totmexpr-mxsav //remove savings from remittance figure

**(NOTE) I MISSED ON THIS KEEP BELOW THE VARIABLE clustnum
keep hhid hhexp hhexp_b 
sort hhid
*merge hhid using "E:\4th Year\KLENOW_RA\MEX_02.dta"
merge 1:m hhid using "`pete_raw_data_root'/MEX_`yy'.dta"

order hhid pcode hhsize age hhexp hhexp_b rcweight 
sort hhid pcode
drop _merge
keep if pcode~="."
*save "E:\4th Year\KLENOW_RA\MEX_02.dta", replace
save "`pete_raw_data_root'/MEX_`yy'.dta", replace
}


*bring in income for comparison
*Open constructed HH monthly income
*hhinc includes: rent  income, remittances, regular wage income, 
*	first casual income, second casual income,  agricultural  income, 
*	self-employment income, housing/food support if needed
qui {
*use "E:\ENIGH\2002\dbf_02\concen_2002.dta", clear
use "`pete_raw_data_root'/Mexico/`yyyy'/concen_`yyyy'.dta", clear
destring ingtot, replace

rename folio hhid
gen hhinc= ingtot/3
keep hhid hhinc
sort hhid
*merge 1:m hhid using "E:\4th Year\KLENOW_RA\MEX_02.dta"
merge 1:m hhid using "`pete_raw_data_root'/MEX_`yy'.dta"
*order hhid pcode hhsize age gender hhinc hhexp
* Why not the following line instead of the previous line of code?
*order hhid pcode hhsize age hhexp hhinc rcweight
sort hhid pcode
drop _merge
keep if pcode~="."
*save "E:\4th Year\KLENOW_RA\MEX_02.dta", replace
save "`pete_raw_data_root'/MEX_`yy'.dta", replace
}


**Compute monthly individual hrs worked from weekly hours worked
quietly {
use "`pete_raw_data_root'/Mexico/`yyyy'/pobla_`yyyy'.dta", clear
gen agr=0
*if `yyyy'==1984 {
	destring th_semana, replace
	rename th_semana hours_wo
	replace agr=1 if rama=="01"
*}
/*else if `yyyy'==2002 {
	destring hrs_sem hrs_sec, replace
	gen hours_wo= hrs_sem + hrs_sec
	replace agr=1 if rama=="111" | rama=="112" | rama=="113" | rama=="114" | rama=="116"
}
else if `yyyy'==2006 {
	destring horas_trab, replace
	rename horas_trab hours_wo
	gen scian=substr(scian101,1,3)
	replace agr=1 if scian=="111" | scian=="112" | scian=="113" |scian=="114" | scian=="115"
	destring cmo201, replace
	gen trab_sec=0
	replace trab_sec=1 if cmo201==.
	* [aim: since trab_sec is never used again, for conformity I'm going to allow it to be dropped. 
	* If we did care about this variable, best practice would be to set it as missing in other 
	* years, and conform code to most inclusive set of variables]
}
*/
rename folio hhid
rename num_ren pcode

keep hhid pcode hours_wo agr
*gen mohours=hours_wo*(52/12) //changed to monthly hours worked = weekly hours worked*(52/12), from weekly hours worked*(4.5)
lab var hours_wo "Weekly Hours Worked"
lab var agr "Working in Agriculture"
sort hhid pcode
*merge hhid pcode using "E:\4th Year\KLENOW_RA\MEX_02.dta"
merge 1:1 hhid pcode using "`pete_raw_data_root'/MEX_`yy'.dta"
drop _merge
}
drop if hours_wo<0 
*drops negative labor hours (118 dropped)
drop if hhexp==. 
*drops obs with missing expenditures values [aim: these were the age 0 people! as a general rule, now these are not dropped]
drop if hhinc==. 
*drops obs with missing income values 

**(NOTE) I WILL DROP ALSO NEGATIVE INCOME
drop if hhinc<0


quietly {
sort hhid pcode
gen hrs_week=0
replace hrs_week=hours_wo if hours_wo<.
}
noi tab hrs_week if hrs_week>=(7*16) 
* [aim: I changed the next line to > rather than >= . Another choice here would be to censor at 7*16, rather than truncate]
drop if hrs_week>(7*16) 
*drops extreme values exceeding maximum available monthly working hrs
local workweeks_MEX_84 = 41.4
local workweeks_MEX_02 = 43.3
local workweeks_MEX_06 = 43.2

quietly {
gen leisure=1-((`workweeks_MEX_`yy''*hrs_week)/(365*16))
gen wave=`yyyy'
lab var leisure "Total Annual Leisure Hours"
* there are 3 obs with hhinc<0, make sure to drop them when want log income later

**(NOTE) I DROPPED IN THE ORDERING PERS_RES WHICH I DON'T KNOW WHAT IT MEANS
order hhid pcode wave hhsize age hhexp hhinc leisure rcweight rel_head hrs_week ed* agr
sort hhid pcode wave
*save "E:\4th Year\KLENOW_RA\MEX_02.dta", replace
save "`pete_raw_data_root'/MEX_`yy'.dta", replace
}



*Use Census raised weight (rcweight) rather than Enumerated raised weight (rsweight). Census raised weights are 
*	considered accurate at the aggregate level. Census raised weights deviate from enumerated raised weights 
*	"where the provincial breakdown is concerned" (pg 9)
*	From LSMS OVERVIEW OF THE SOUTH AFRICA INTEGRATED HOUSEHOLD SURVEY, page 8: "The census population for the survey 
*	data was estimated by applying Sadie's population growth rates to the adjusted 1991 census figures...This implies 
*	that a raising factor of 891.4154 (40.1 million divided by an expected take of 45,000) should be applied to the 
*	results weighted by enumeration to obtain the population it represents"

**(NOTE) I AM NOT SURE THAT THE ABOVE APPLIES FOR ME
**(NOTE) I WILL USE JUST THE NORMAL WEIGHTS

svyset [pweight=rcweight]

**I just added as a comment since it point me out an error
**svymean hhsize age hhexp hhinc leisure
svy: mean hhsize age hhexp hhexp_b hhinc leisure


*normalize weights to sum to 1
sum rcweight
gen weight=rcweight/r(sum)
lab var weight "Normalized Individual Weight"

keep hhid hhsize age hhexp leisure weight
order hhid hhsize age hhexp leisure weight
save "`pete_raw_data_root'/MEX_`yy'.dta", replace
format weight %11.4e
describe
summarize
*list
outfile using "`pete_raw_data_root'/MEX_`yy'.txt" , wide noquote  replace

*log close
*exit

**(NOTE ABOUT VARIABLES)
**household ID number =(folio)
** person code= (num_ren)
** relationship to head=(parentesco)
** age in years =(edad)
** education (ed_formal, ed_tecnica)
