* change the working directory and load the data
clear all
*cd "C:\Zach\Projects\Italy Data\Raw Data"
*cd "C:\Zach\Projects_Pete\Italy Data\Raw Data"
cd "C:\Users\Rui\Dropbox\Beyond_GDP\ITA"
use "red0.dta"
rename eta age
rename sesso sex
* Drop people out of the [0,100] age range
* With 1887 negative, 30 larger than 100 and 

* Keep the data in 2006
drop if year !=2006

**[Rui: create hhsize before dropping any observation]
sort nquest
by nquest: gen hhsize = _N

drop if age <= 0 
drop if age > 100
drop if age==.


* Drop consumption smaller than zero
drop if c <0
drop if cn1 <0
drop if cn2 <0


qui {
keep nquest nord ncomp age y2 oredip oreaut pesofl pesofit c cn1 cn2 mesiaut mesidip par hhsize
rename nquest hhid
rename nord indid
rename ncomp hhsize_data
rename par pcode
label var pcode "household position"
* y2 net disposable income (including property income)
rename y2 hhinc 
label var hhinc "net disposable household income"
sort hhid indid
}

*test hhsize: perfect match!
gen diff = hhsize - hhsize_data
tab diff

* total hours worked in a week
replace mesiaut = 0 if mesiaut==.
replace mesidip = 0 if mesidip==.
replace oreaut = 0 if oreaut==.
replace oredip = 0 if oredip==.

gen hrs = oreaut*mesiaut*4 + oredip*4*mesidip
* Drop weekly working hours larger than total weekly waking hours (16*7)
label var hrs "total worked hours per week"
gen leisure = (5840 - hrs)/5840
drop if leisure <=0
drop if leisure >1
label var leisure "the proportion of total hours in a year that a person does not work"
gen cn = cn1 + cn2
label var cn "non-durable consumption"


rename cn hhexp
rename c hhexp_total
rename pesofl weight
rename pesofit weight_impRent
* normalize weights to sum to 1
summ weight
gen wt=weight/r(sum)
lab var wt "Normalized Individual Weight"

*summ weight_impRent
*gen wt_impRent=weight_impRent/r(sum)
*lab var wt_impRent "Normalized Individual Weight for imputed rents"

qui{
keep hhid hhsize age hhexp leisure wt  
rename wt weight
sort hhid 
order hhid hhsize age hhexp leisure weight
save "ITA_06.dta", replace
format weight %11.4e
outfile using "ITA_06.txt", replace wide
}



