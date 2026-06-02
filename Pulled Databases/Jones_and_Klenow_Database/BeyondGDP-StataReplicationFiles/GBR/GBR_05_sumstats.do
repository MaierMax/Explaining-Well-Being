* change the working directory and load the data
clear all
*cd "C:\Zach\Projects\Italy Data\Raw Data"
*cd "C:\Zach\Projects_Pete\UK"
*cd "C:\Users\Rui\Dropbox\Beyond_GDP\GBR"
*cd "/Users/xurui/Dropbox/Beyond_GDP/GBR"
*cd "C:\Users\klenow.ECON\Dropbox\Beyond_GDP\GBR"
cd "C:\Users\klenow\Dropbox\Beyond_GDP\GBR"

use "merged_inc_ind.dta",clear
* Merge with the household data and keep the data in 2005
keep persno hhref yrm year week age L hours
merge m:m hhref yrm using "merged_hh_resid.dta"
drop _merge

drop if year != 2005
/*
**[Rui: create hhsize before dropping any observation]
sort hhref
by hhref: gen hhsize = _N
*/
drop if age <= 0 
drop if age > 100
drop if age==.
*saveold "GBR_05.dta", replace

keep persno year hhref L age hours Y_D C C_p numads numhhkid weighta
rename persno pcode
rename hhref hhid
rename Y_D hhinc
gen hhsize = numads + numhhkid
drop if hhsize ==.
drop if hhsize <=0
label var pcode "household position"
label var hhsize "household size"
label var hhinc "household net income"
label var C_p "non-durable consumption plus real housing costs"

* Drop negative/missing consumption/income
drop if C_p <= 0
drop if C_p ==.
drop if hhinc < 0
drop if hhinc ==.

* Make sure Hours worked and hours of work matching each other
gen duplicate = L - hours
drop if duplicate != 0 
drop duplicate

* Drop weekly working hours larger than total weekly waking hours (16*7)
gen hrs = hours * 45
label var hrs "total worked hours per week"
gen leisure = (5840 - hrs)/5840
drop if leisure <= 0
drop if leisure > 1
label var leisure "the proportion of total hours in a year that a person does not work"

rename C_p hhexp
rename weighta weight_sample

keep hhid pcode hhsize age leisure hhexp weight_sample hhinc numhhkid
order hhid pcode hhsize age hhinc leisure hhexp weight_sample numhhkid
sort hhid pcode
saveold "GBR_05_org.dta", replace


*****************************************************************
** Creat the data for the young
*****************************************************************
use "GBR_05_org.dta",clear

* Average, take first values of variables for each hhid
collapse (mean) hhexp=hhexp hhinc=hhinc weight_sample=weight_sample ///
         (first)hhsize=hhsize numhhkid=numhhkid, by(hhid)

* Rename and generate variables for individuals to prepare for reshape

tabstat hhsize, stat(sum)

gen age1 = 24
gen rleisure1 = 1
gen rweight1 = numhhkid*weight_sample/24
gen pcode1=1

gen age2 = 23
gen rleisure2 = 1
gen rweight2 = numhhkid*weight_sample/24
gen pcode2=2

gen age3 = 22
gen rleisure3 = 1
gen rweight3 = numhhkid*weight_sample/24
gen pcode3=3

gen age4 = 21
gen rleisure4 = 1
gen rweight4 = numhhkid*weight_sample/24
gen pcode4=4

gen age5 = 20
gen rleisure5 = 1
gen rweight5 = numhhkid*weight_sample/24
gen pcode5=5

gen age6 = 19
gen rleisure6 = 1
gen rweight6 = numhhkid*weight_sample/24
gen pcode6=6

gen age7 = 18
gen rleisure7 = 1
gen rweight7 = numhhkid*weight_sample/24
gen pcode7=7

gen age8 = 17
gen rleisure8 = 1
gen rweight8 = numhhkid*weight_sample/24
gen pcode8=8

gen age9 = 16
gen rleisure9 = 1
gen rweight9 = numhhkid*weight_sample/24
gen pcode9=9

gen age10 = 15
gen rleisure10 = 1
gen rweight10 = numhhkid*weight_sample/24
gen pcode10=10

gen age11 = 14
gen rleisure11 = 1
gen rweight11 = numhhkid*weight_sample/24
gen pcode11=11

gen age12 = 13
gen rleisure12 = 1
gen rweight12 = numhhkid*weight_sample/24
gen pcode12=12

gen age13 = 12
gen rleisure13 = 1
gen rweight13 = numhhkid*weight_sample/24
gen pcode13=13

gen age14 = 11
gen rleisure14 = 1
gen rweight14 = numhhkid*weight_sample/24
gen pcode14=14

gen age15 = 10
gen rleisure15 = 1
gen rweight15 = numhhkid*weight_sample/24
gen pcode15=15

gen age16 = 9
gen rleisure16 = 1
gen rweight16 = numhhkid*weight_sample/24
gen pcode16=16

gen age17 = 8
gen rleisure17 = 1
gen rweight17 = numhhkid*weight_sample/24
gen pcode17=17

gen age18 = 7
gen rleisure18 = 1
gen rweight18 = numhhkid*weight_sample/24
gen pcode18=18

gen age19 = 6
gen rleisure19 = 1
gen rweight19 = numhhkid*weight_sample/24
gen pcode19=19

gen age20 = 5
gen rleisure20 = 1
gen rweight20 = numhhkid*weight_sample/24
gen pcode20=20

gen age21 = 4
gen rleisure21 = 1
gen rweight21 = numhhkid*weight_sample/24
gen pcode21=21

gen age22 = 3
gen rleisure22 = 1
gen rweight22 = numhhkid*weight_sample/24
gen pcode22=22

gen age23 = 2
gen rleisure23 = 1
gen rweight23 = numhhkid*weight_sample/24
gen pcode23=23

gen age24 = 1
gen rleisure24 = 1
gen rweight24 = numhhkid*weight_sample/24
gen pcode24=24

summarize hhsize hhexp hhinc

/* Reshape from wide form to long form (each member becomes an observation). */
reshape long age rleisure pcode rweight, i(hhid) j(lineno)
summarize

drop if rweight <= 0
drop if rweight==.

qui {
keep hhid pcode hhsize age hhexp hhinc rleisure rweight numhhkid 
rename rleisure leisure
rename rweight weight_sample
sort hhid pcode
}

keep age hhid pcode hhexp hhinc leisure hhsize weight_sample numhhkid
saveold "GBR_05_young.dta", replace

**********************************************************************
*  Append the original data with the created young data
**********************************************************************
use "GBR_05_org.dta",clear
app using "GBR_05_young.dta"

sort hhid pcode

summ weight_sample
gen weight = weight_sample/r(sum)
lab var weight "Normalized Individual Weight"

keep hhid hhsize age hhinc hhexp leisure weight
saveold "GBR_05.dta",replace
drop hhinc
order hhid hhsize age hhexp leisure weight
format weight %11.4e
outfile using "GBR_05.txt", wide replace



