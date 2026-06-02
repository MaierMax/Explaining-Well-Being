*********************************************************
* Title: CHIP data processing
* Author: Rui Xu
* Update on Jan 13, 2012
**********************************************************

* change the working directory and load the data
clear all
set more off
set mem 500m

*cd "/Users/xurui/Dropbox/Projects_Pete/CHIP Data sets\CHN"
cd "C:\Users\Rui\Dropbox\Beyond_GDP\CHN"
cap log close
log using CHIP_Datacleaning.log, replace

*******************************************************
** Urban Data
********************************************************
use "CHIP_Urban_hh_2002.dta"
keep PCODE E B21 D952 D953 D954 D96

* Merge with the household data 
merge 1:m PCODE using "CHIP_Urban_Ind_2002.dta"

**[Rui: create hhsize before dropping any observation]

drop _merge

sort PCODE

by PCODE: gen hhsize_rui=_N

drop if B21 <=0
drop if B21 ==. 

drop if E <= 0
drop if E == .

*test hhsize: perfect match! so using hhsize from the dataset is fine.
gen diff = hhsize_rui - hhsize
tab diff

* calculate HH Income by aggregating individual income in a hh
sort PCODE P102
by PCODE: egen hhinc = total(P201)

sum(PCODE)
*gen weight = 1/r(N)
keep PCODE CODE_P P102 B21 E D952 D953 D954 D96 P106 P147 P147A P147B P201 hhinc
sum(PCODE)    /*20404  obsv*/




**Rename the variables
* member ID
rename P102 pcode     
* HH ID
rename PCODE hhid
* HH size
rename B21 hhsize 
* age
rename P106 age
* HH net consumption
rename E hhexp
*Hours worked
rename P147 workmonth
rename P147A workdays
rename P147B workhours

drop if age <=0
drop if age >100
drop if age ==.
* round up to integer ages
replace age = round(age)

*save the dataset
order hhid CODE_P pcode hhsize hhexp hhinc age workmonth workhours workdays P201 D952 D953 D954 D96 
save "CHIP_Urban_2002.dta", replace

label var pcode "household position"
label var hhsize "household size"
label var hhinc "household net income"
label var hhexp "non-durable consumption plus real housing costs"

* Drop negative/missing consumption/income
drop if hhexp <= 0
drop if hhexp ==.
drop if hhinc < =0	/*44 observations deleted*/
drop if hhinc ==.    

* force hours worked to be zero for ALL missing hours
replace workmonth =0 if workmonth ==.   /*10153 changes made*/
replace workdays =0 if workdays ==. 
replace workhours =0 if workhours ==. 

* Drop weekly working hours larger than total weekly waking hours (16*7)
gen hrs = workmonth*workdays*workhours
label var hrs "total hours worked"
gen leisure = (5840 - hrs)/5840
drop if leisure <= 0
drop if leisure > 1
label var leisure "the proportion of total hours in a year that a person does not work"

sum(leisure) 

keep hhid pcode hhsize age leisure hhexp hhinc
order hhid pcode hhsize age hhinc leisure hhexp
sort hhid pcode
save "Urban_cleaned_2002.dta", replace

*graph twoway scatter leisure age 

************compute the ratio of monthly rent/house value**************
use "CHIP_Urban_hh_2002.dta", clear
keep PCODE F711 F712 B28 B29 B210
sum(PCODE)  /*6835 hh in total */

*drop missing values, zeros 
/*Note: there are two potential variables for rent, 
one in expenditure section (F711, F712) and one in housing situation section (B29, B210)
I use B29 and B210 here because there are too many rent == 0 using F711 and F712 */

drop if B28   <=0
drop if B28   == .
drop if B29   == .
drop if B210 == .
gen rent = max(B29, B210)
drop if rent <= 0  /* 275 hh deleted */

*drop unmatched rents
drop if B29!= 0 & B210 != 0 & B29 != B210

rename B28 HValue

*generate the rent/(house value) ratio
gen RentRatio = rent / HValue


*calculate the average ratio
sum(RentRatio)  /*mean ratio is .0018646 for future use */
scalar rent_ratio = r(mean)
save "rent_ratio.dta", replace
*****************************************
** Rural Data 
*****************************************
use "CHIP_Rural_hh_2002.dta", clear
keep COUN VILL HOUS H1_500 H1_601 H1_602 H1_603 H1_604 H1_605 H1_606 /*
*/H1_608 H1_609 H1_610C H1_616D H1_704 H1_85 H1_84

sum(HOUS)   /*9200 hh*/
*gen weight  = 1/r(N)

gen double hhid = COUN*1000 + VILL*10 + (HOUS-1)

* Merge with the household data 
merge m:m COUN VILL HOUS using "CHIP_Rural_Ind_2002.dta"
drop _merge

sort hhid P1_2
sum(HOUS) /*37969 obsv */

keep hhid P1_2 H1_500 H1_601 H1_602 H1_603 H1_604 H1_605 H1_606 H1_608 /*
*/H1_609 H1_610C H1_616D H1_704 P1_5 P1_30 P1_31 P1_32 P1_33 P1_34 P1_35 P1_36 /*
*/P1_37 P1_61 P1_62 P1_64 P1_65 H1_85 H1_84 

*rename the variables
rename P1_2 pcode
rename P1_5 age
rename H1_500 hhinc
rename H1_85 hhsize_data

**[Rui: create hhsize before dropping any observation]
sort hhid
by hhid: gen hhsize = _N
* test: 
gen diff = hhsize_data - hhsize
tab diff

drop if age <=0
drop if age >100
drop if age ==.
* round up to integer ages
replace age = round(age)
drop if hhinc <= 0
drop if hhinc ==.
drop if hhsize ==.
drop if hhsize <= 0


/*
hhsize for rural areas is badly recorded...
So use by hhid: gen hhsize = _N

       diff |      Freq.     Percent        Cum.
------------+-----------------------------------
         -5 |         14        0.04        0.04
         -4 |         28        0.07        0.11
         -3 |         91        0.24        0.35
         -2 |        362        0.95        1.30
         -1 |      1,894        4.99        6.29
          0 |     34,739       91.49       97.79
          1 |        656        1.73       99.51
          2 |        113        0.30       99.81
          3 |         45        0.12       99.93
          4 |         17        0.04       99.97
          5 |         10        0.03      100.00
------------+-----------------------------------
      Total |     37,969      100.00
*/

*replace missing values with zero
foreach y in H1_601 H1_602 H1_603 H1_604 H1_605 H1_606 H1_608 /*
*/H1_609 H1_610C H1_616D{
replace `y' = 0 if `y' ==.
}

*calculate HH non-durable expenditure with imputed rent (using ratio from urban survey)
gen hhexp = H1_601+H1_602+H1_603+H1_604+H1_605+H1_606+H1_608+/*
*/H1_609+H1_610C+H1_616D + rent_ratio*12*H1_704
drop if hhexp <= 0

*calculate number of hours worked per month
*step 1: drop observations missing all work time information who are eligible to work
drop if age>=16 & age<=60 & P1_30==. & P1_31==. & P1_32==. & P1_33==. & /*
*/P1_34==. & P1_35==. & P1_36==. &P1_37==. & P1_61==. & P1_62==. & /*
*/P1_64==. & P1_65==. 
 
*step 2: replace missing values with zero 
foreach y in P1_30 P1_31 P1_32 P1_33 P1_34 P1_35 P1_36 /*
*/P1_37 P1_61 P1_62 P1_64 P1_65{
replace `y' = 0 if `y' ==.
}

*step 3: add up all hours worked in a year
gen hrs = P1_30*P1_31 + P1_32*P1_33+P1_34*P1_35+P1_36*P1_37+P1_61*P1_62 /*
*/+P1_64*P1_65

*step 4: adjust work hoursfor children  
*replace hrs = 0 if age<16  /*800 real changes made*/

*relabel variables
label var pcode "household position"
label var hrs "total hours worked"
label var hhinc "household net income"
label var hhexp "non-durable consumption plus real housing costs"
*label var weight "equally-weighted"
label var hhsize "household size"
label var hhid "PCODE"
label var age "Age"

*save the dataset
order hhid pcode hhexp hhsize age hhinc hrs 
save "CHIP_Rural_2002.dta", replace

* Drop weekly working hours larger than total weekly waking hours (16*7)
gen leisure = (5840 - hrs)/5840
drop if leisure <= 0
drop if leisure > 1
label var leisure "the proportion of total hours in a year that a person does not work"

sum(leisure)  /*37890 obsv*/


order hhid hhsize age hhinc leisure hhexp 
keep hhid hhsize age hhinc hhexp leisure 
sort  hhid
save "Rural_cleaned_2002.dta", replace

*******************************************************
* Combine Urban and Rural data
*******************************************************
use "Rural_cleaned_2002.dta", clear
app using "Urban_cleaned_2002.dta"
sum age
return list
scalar population = r(N)

sort hhid
gen weight = 1/population
format hhid %20.0f
keep hhid hhsize age hhexp leisure weight
order hhid hhsize age hhexp leisure weight
format weight %11.4e
save "CHN_02.dta",replace
format weight %11.4e
outfile using "CHN_02.txt",wide noquote replace
log close




