clear all 
*cd "C:\Zach\Projects_Pete\Brazil\PNAD\Data_2008\Dados"
cd "C:\Users\Rui\Dropbox\Beyond_GDP\BRA\Raw Data\Raw Data\PNAD\Data_2008\Dados"

insheet using "PES_2008_Leisure.txt"
save "Brazil_08_Leisure.dta",replace

use "Brazil_08_Leisure.dta",clear
rename monthlyhhinc_per inc_per
rename serial_2 pid

*drop all observations missing income information
drop if inc_per == "NA"
destring inc_per, replace 
drop if inc_per <=0
************************Rui edit *********************************
***TEST****
* Some difference between calculated household size (size) and original data (hhsize)
* hhsize < size, because hhsize infor is missing for some observations and hhsize is 
* calculated with non-missing 
sort hhid
by hhid: gen hhsize_rui = _N
destring hhsize, replace
gen diff = hhsize_rui - hhsize
sort diff

/*
. tab diff

       diff |      Freq.     Percent        Cum.
------------+-----------------------------------
          0 |    352,208       91.71       91.71
          1 |         16        0.00       91.71
          2 |     13,622        3.55       95.26
          3 |      8,341        2.17       97.43
          4 |      4,409        1.15       98.58
          5 |      2,309        0.60       99.18
          6 |      1,394        0.36       99.54
          7 |        712        0.19       99.73
          8 |        340        0.09       99.82
          9 |        271        0.07       99.89
         10 |        163        0.04       99.93
         11 |        103        0.03       99.96
         12 |         57        0.01       99.97
         13 |         46        0.01       99.98
         14 |         43        0.01       99.99
         15 |         20        0.01      100.00
------------+-----------------------------------
      Total |    384,054      100.00

There are something wrong with the income data, as income per capita does not stay
constant within 1 hhid. The hhsize calculated by Zach is based on the number
of observations within the same hhid and with the same income level. The
hhsize calculated by hhid: gen hhsize_rui = _N is larger for many cases... 	  
	  
*/


******************************************************************

*drop if hhsize == "NA"  
*destring,replace
drop if hhsize < = 0
* Age == 0, accounts for 1.4% of the data.
* Adjust for age, relabelling from 0-99 to 1-100
gen new_age = age + 1 
drop if new_age >100
drop if new_age <=0
* drop the missing value
drop if inc_per >= 999999999999
drop if inc_per < = 0
gen hhinc = inc_per * hhsize * 12
label var hhinc "Annual Household Income"

sort hhid pid
replace hrs = "0" if hrs == "NA"
lab var hrs "Hrs worked per week for kids under 15"
replace hrs_1 = "0" if hrs_1 == "NA"
replace hrs_2 = "0" if hrs_2 == "NA"
replace hrs_3 = "0" if hrs_3 == "NA"
destring,replace

replace hrs = 0 if hrs == 99
replace hrs_1 = 0 if hrs_1 == 99
replace hrs_2 = 0 if hrs_2 == 99
replace hrs_3 = 0 if hrs_3 == 99

* Convert all the missing values to zero. 
gen hrs_week = hrs + hrs_1 + hrs_2 + hrs_3
*replace hrs_week =. if (age >=22 & hrs_week == 0)
*replace hrs_week =0 if (age >=50 & hrs_week == .)
* Delete all the entires which do not have the hrs info
*drop if hrs_week ==.

* Calculating Leisure - using OECD average working weeks in 2008
scalar num_of_weeks = 1767/38.9
gen leisure = (5840-hrs_week*num_of_weeks)/5840
drop if leisure <=0
drop if leisure >1
label var leisure "the proportion of total hours in a year that a person does not work"

summ wt
gen weight = wt/r(sum)
lab var weight "Normalized Weight"

keep hhid hhsize new_age leisure weight
rename new_age age
order hhid hhsize age leisure weight
save "C:\Users\Rui\Dropbox\Beyond_GDP\BRA\Calculation\BRA_08_Leisure.dta",replace
format weight %11.4e
format hhid %20.0f
outfile using "C:\Users\Rui\Dropbox\Beyond_GDP\BRA\BRA_08_leisure.txt",wide noquote replace

