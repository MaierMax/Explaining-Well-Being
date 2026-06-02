clear all 
*cd "C:\Zach\Projects_Pete\Brazil\PNAD\Data_2003"
cd "C:\Users\Rui\Dropbox\Beyond_GDP\BRA\Raw Data\Raw Data\PNAD\Data_2003"

insheet using "PES_2003_Leisure.txt"
save "Brazil_03_Leisure.dta",replace
rename serial_2 pid
* Some difference between calculated household size (size) and original data (hhsize)
egen size = count(hhid), by (hhid)

drop if hhsize == "NA" 
* Droping the missing value of income and the negative value 
* Vast majority (89%) of inc_1 and inc_2 are the same
* We use inc_1 as the household income as inc_1 is larger than inc_2 in general
drop if inc_1 == "NA"
destring,replace
* Age == 0, accounts for 1.4% of the data.
* Adjust for age, relabelling from 0-99 to 1-100
gen new_age = age + 1 
drop if new_age >100
drop if new_age <=0

* drop the missing value
drop if inc_1 >= 999999999999
drop if inc_1 < = 0

gen hhinc = inc_1 * 12
label var hhinc "annual househld income"
replace hrs_kids = "0" if hrs_kids == "NA"
lab var hrs_kids "Hrs worked per week for kids under 15"
replace hrs_1 = "0" if hrs_1 == "NA"
replace hrs_2 = "0" if hrs_2 == "NA"
replace hrs_3 = "0" if hrs_3 == "NA"
destring,replace
* Hours are bounded between 1 and 98
replace hrs_kids = 0 if hrs_kids == 99
replace hrs_1 = 0 if hrs_1 == 99
replace hrs_2 = 0 if hrs_2 == 99
replace hrs_3 = 0 if hrs_3 == 99

gen hrs_week = hrs_kids + hrs_1 + hrs_2 + hrs_3

* Calculating Leisure - using OECD average working weeks in 2003
scalar num_of_weeks = 1785/39
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

save "C:\Users\Rui\Dropbox\Beyond_GDP\BRA\Calculation\BRA_03_Leisure.dta",replace
format weight %11.4e
format hhid %20.0f
outfile using "C:\Users\Rui\Dropbox\Beyond_GDP\BRA\BRA_03_Leisure.txt",wide noquote replace

