********************************************************
**PROGRAM 1: GENERATING COUNTRY DATASET COUNTRY_YR.DTA**
********************************************************

* Open cleaned HH roster
*use "C:\Users\klenow\Documents\Rawls\USA\fabrizio_cex.dta", clear
*use "C:\Users\Pete\Dropbox\Beyond_GDP\USA\Sumstats\fabrizio_cex.dta", clear
use "C:\Users\Klenow\Dropbox\Beyond_GDP\USA\Sumstats\fabrizio_cex.dta", clear

* Rename variables, select year, and create hhexp, hhinc

rename id hhid
rename famsize hhsize
gen hhinc = incaftax/4

gen year = intyea + 1900
keep if year == 1993

gen hhexp = nondurn + veisern + veiothn + housesern + rentrn + othlodn + entern
keep if hhexp~=.

* Average, take first values of variables for each hhid
collapse (mean) hhexp=hhexp hhinc=hhinc refwks=refwks refhpw=refhpw weight=weight ///
                spowks=spowks spohpw=spohpw ///
         (first) hhsize=hhsize nbab=nbab nmu15=nmu15 nwu15=nwu15 ///
                 spoage=spoage refage=refage, by(hhid)

* Rename and generate variables for individuals to prepare for reshape

   tabstat hhsize, stat(sum)

   gen nooadults = hhsize - 1 - (nbab + nmu15 + nwu15) - min(spoage,1)

	rename refage age1
	gen leisure1=(5840/12-refwks*refhpw/12)/(5840/12) // 16*365=5840, yearly hrs available given 8hrs sleep
	gen rweight1 = weight 
	gen pcode1=1

	rename spoage age2
	gen leisure2=(5840/12-spowks*spohpw/12)/(5840/12)
	gen rweight2 = weight
	gen pcode2=2

	gen age3 = 24
	gen leisure3 = 1
	gen rweight3 = nooadults*weight/(24-15)
	gen pcode3=3

	gen age4 = 23
	gen leisure4 = 1
	gen rweight4 = nooadults*weight/(24-15)
	gen pcode4=4

	gen age5 = 22
	gen leisure5 = 1
	gen rweight5 = nooadults*weight/(24-15)
	gen pcode5=5

	gen age6 = 21
	gen leisure6 = 1
	gen rweight6 = nooadults*weight/(24-15)
	gen pcode6=6

	gen age7 = 20
	gen leisure7 = 1
	gen rweight7 = nooadults*weight/(24-15)
	gen pcode7=7

	gen age8 = 19
	gen leisure8 = 1
	gen rweight8 = nooadults*weight/(24-15)
	gen pcode8=8

	gen age9 = 18
	gen leisure9 = 1
	gen rweight9 = nooadults*weight/(24-15)
	gen pcode9=9

	gen age10 = 17
	gen leisure10 = 1
	gen rweight10 = nooadults*weight/(24-15)
	gen pcode10=10

	gen age11 = 16
	gen leisure11 = 1
	gen rweight11 = nooadults*weight/(24-15)
	gen pcode11=11

	gen age12 = 15
	gen leisure12 = 1
	gen rweight12 = (nmu15 + nwu15)*weight/(15-2)
	gen pcode12=12

	gen age13 = 14
	gen leisure13 = 1
	gen rweight13 = (nmu15 + nwu15)*weight/(15-2)
	gen pcode13=13

	gen age14 = 13
	gen leisure14 = 1
	gen rweight14 = (nmu15 + nwu15)*weight/(15-2)
	gen pcode14=14

	gen age15 = 12
	gen leisure15 = 1
	gen rweight15 = (nmu15 + nwu15)*weight/(15-2)
	gen pcode15=15

	gen age16 = 11
	gen leisure16 = 1
	gen rweight16 = (nmu15 + nwu15)*weight/(15-2)
	gen pcode16=16

	gen age17 = 10
	gen leisure17 = 1
	gen rweight17 = (nmu15 + nwu15)*weight/(15-2)
	gen pcode17=17

	gen age18 = 9
	gen leisure18 = 1
	gen rweight18 = (nmu15 + nwu15)*weight/(15-2)
	gen pcode18=18

	gen age19 = 8
	gen leisure19 = 1
	gen rweight19 = (nmu15 + nwu15)*weight/(15-2)
	gen pcode19=19

	gen age20 = 7
	gen leisure20 = 1
	gen rweight20 = (nmu15 + nwu15)*weight/(15-2)
	gen pcode20=20

	gen age21 = 6
	gen leisure21 = 1
	gen rweight21 = (nmu15 + nwu15)*weight/(15-2)
	gen pcode21=21

	gen age22 = 5
	gen leisure22 = 1
	gen rweight22 = (nmu15 + nwu15)*weight/(15-2)
	gen pcode22=22

	gen age23 = 4
	gen leisure23 = 1
	gen rweight23 = (nmu15 + nwu15)*weight/(15-2)
	gen pcode23=23

	gen age24 = 3
	gen leisure24 = 1
	gen rweight24 = (nmu15 + nwu15)*weight/(15-2)
	gen pcode24=24

	gen age25 = 2
	gen leisure25 = 1
	gen rweight25 = nbab*weight/2
	gen pcode25=25

	gen age26 = 1
	gen leisure26 = 1
	gen rweight26 = nbab*weight/2
	gen pcode26=26

summarize hhsize hhexp hhinc

/* Reshape from wide form to long form (each member becomes an observation). */
reshape long age leisure pcode rweight, i(hhid) j(lineno)

drop if age<=0
drop if age>100
drop if age==.

drop if leisure <= 0
drop if leisure > 1
drop if leisure==.

drop if rweight <= 0
drop if rweight==.

* Keep relevant variables: household ID number, age in years, hhexp, leisure, weight

qui {
keep hhid pcode hhsize age hhexp hhinc leisure rweight 
sort hhid 
}



svyset [pweight=rweight]
*svymean hhsize age hhexp hhinc leisure  // Stata 10 format
svy: mean hhsize age hhexp hhinc leisure  // Stata 11 format

*normalize weights to sum to 1
summ rweight
gen weight=rweight/r(sum)
lab var weight "Normalized Individual Weight"

keep age hhid pcode hhexp hhinc leisure hhsize weight
*save "C:\Users\klenow\Documents\Rawls\USA\USA_93", replace
*save "C:\Users\Pete\Dropbox\Beyond_GDP\USA\Sumstats\USA_93", replace
save "C:\Users\Klenow\Dropbox\Beyond_GDP\USA\Sumstats\USA_93", replace

describe
summarize
*list

outsheet hhid pcode age hhexp leisure weight using USA_93.csv , comma replace

exit
