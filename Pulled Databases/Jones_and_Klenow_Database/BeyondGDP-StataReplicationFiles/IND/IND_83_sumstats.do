********************************************************
**PROGRAM 1: GIVES SUMMARY STATS FOR INDIA 1983		  **
**There are separate files for leisure and exp here   **
********************************************************



** 3 do-files generated the data used for 1983. rural_38.do and urban_38.do generated 2 datsets each, 1 for 
** leisure and one for expenditure.
** Then, ind_83_gendata.do combined the urban and rural datsets. However, the expenditure data does not have
** data on age. Therefore only those households who were matched by the matching algorithm were kept in the
** expenditure dataset. Eventually we have 2 files. These are, ind_83_exp.dta and ind_83_leisure.dta
** These do-files are appended below

*use "C:\Users\Siddharth\Documents\phd\pete\Rawls\stata_copy\stata\38\Rawls\final\ind_83_exp.dta", clear
* use "C:\Users\klenow\Documents\Rawls\IND\ind_83_exp.dta", clear
*cd "C:\Users\Rui\Dropbox\Beyond_GDP\IND\CFE Labor\1983"
cd "/Users/xurui/Dropbox/Beyond_GDP/IND"
*cd "C:\Users\Rui\Dropbox\Beyond_GDP\IND"
use "CFE Labor/1983/ind_83_exp.dta", clear

replace age=age+1
*replace age=100 if age>=100
drop if age > 100
drop if age==.
*ren weight_c weight
egen weight_c_total=total(weight_c)
gen weight = weight_c/weight_c_total
drop weight_c weight_c_total

svyset [pweight=mult_c]
*svymean hhsize age hhexp hhinc leisure
svy: mean hhsize age exp

keep hhid hhsize age exp weight
rename exp hhexp
order hhid hhsize age hhexp weight
format hhid %20.0f
save "IND_83_exp.dta",replace
format weight %11.4e
outfile using "IND_83_exp.txt", replace wide

describe
summarize
*list


drop _all


*** LEISURE *** 

*use "C:\Users\Siddharth\Documents\phd\pete\Rawls\stata_copy\stata\38\Rawls\final\ind_83_leisure.dta", clear
* use "C:\Users\klenow\Documents\Rawls\IND\ind_83_leisure.dta", clear
use "CFE Labor/1983/ind_83_leisure.dta", clear

replace age=age+1
*replace age=100 if age>=100
drop if age > 100
drop if age==.
rename weight weight_l
egen weight_l_total=total(weight_l)
gen weight = weight_l/weight_l_total
drop weight_l weight_l_total

svyset [pweight=mult_l]
*svymean hhsize age leisure
svy: mean hhsize age leisure

keep hhid hhsize age leisure weight
order hhid hhsize age leisure weight
format hhid %20.0f
save "IND_83_leisure.dta",replace
format weight %11.4e
outfile using "IND_83_leisure.txt", replace wide
describe
summarize

exit




***** rural_38.do
******************************************************
**PROGRAM 2:   GENERATING RURAL DATA				**
******************************************************

#delimit ;
clear;
set mem 500m;

*log using "rural_38.smcl", replace;

*********** GENERATING LEISURE AND CONSUMPTION ******************;

*********** Rural Data - 38th Round - 1983 **********************;


***********EXPENDITURE USING SCHEDULE 1 *************************;
*cd "C:\Users\Rui\Dropbox\Beyond_GDP/rawls/38";
cd "/Users/xurui/Dropbox/Beyond_GDP/rawls/38";
use "1/dl0114/dl0114r_l14.dta", clear;
* Data is a summary of all expenditure. However, the structure of the dataset is a little weird. Every hhid has multiple
*observations with each observation having 7 itemcodes. Therfore, if a household consumes more than 7 broad categories, then
*a new observation is started. The collapse command takes care of this in the end. *;

* We first generate variables for total expenditure (itemcode 31), household size (itemcode 32)and 
*expenditure on durables (itemcode 29)*;

gen totexp=0;
gen hhsz=0;
gen durables=0;

forvalues i=1/7 {;

replace totexp=value`i' if itemcode`i'==31;
replace hhsz=value`i' if itemcode`i'==32;
replace durables=value`i' if itemcode`i'==29;

};
* 8019 households have non zero consumption of durables. 77336 households in total. *;

* Collapse out the multiple households *;

collapse (sum) totexp=totexp hhsz=hhsz durables=durables (mean) mult_comb=mult_comb, by(hhid);

* Removing durables *;
gen exp=totexp-durables;
lab var exp "Expenditure of household after removing durables";

drop if exp<=0;
* 526 observations dropped *;

drop if hhsz==0;
* 13 observations dropped*;

keep hhid exp hhsz mult_comb;
ren mult_comb mult_c;
sort hhid;

save "Rawls/final/india_83_r_exp.dta", replace;

clear;




*********** LEISURE USING SCHEDULE 10 *************************;
#delimit ;

use "10/d156a/d156ar.dta", clear;

* SPECIALCODE=2: "When Daily Activity Status Code in block-5 is 01 to 82, one

           		consolidated record of all the daily activities the person

           		was engaged with, has been created with Special Code 2"
			These observations are dropped as we use the raw (unsummarized) data. *;

drop if specialcode==2;
*157531 observations dropped *;


******* Generating unique identifier *******;
gen double u_id=hhid*1000+ srl_n_m*10+ srl_n_a;
lab var u_id "Unique Identifier for HH-Individual-Activity data";

* There were a lot of problems with duplicates in this file. Going through the cleaning steps *;

duplicates tag u_id, gen(problem);
* There are 564 duplicates at this stage. Furthermore, there are some observations with intensity days as 0. Those observations
which are duplicates and have intensity days as 0 are removed. *;

drop if problem>=1&tot_day==0;
* 477 observations are dropped *;

duplicates tag u_id, gen(problem1);
* There are 88 duplicates at this stage. All household who still have these duplicates are dropped *;

egen problem_hh=max(problem1), by(hhid);
drop if problem_hh>=1;
* 354 observation dropped *;




* There are 2 individuals whose itensity days when summed across all days doesn't add up to 7. Should we also remove these
households? *;



******* Generating Hours Worked Using Time Disposition Data************;


*** Assumption on what contributes towards hours worked. ***;

* In the base case, everyone with activity code less than 60 and equal to 93 is considered working. This corresponds to the
scalar 'employment_rule' taking value 1. If employment_rule takes value 2, then 93 is not considered to be working. *;

scalar employment_rule=2;

gen working=0;
lab var working "Those who are employed";

if employment_rule==1 {;
* Assign value one to the variable 'working' for all those deemed to be working *;
replace working=1 if status_da<60|status_da==93;
};
else {;
replace working=1 if status_da<60;
};



* The hours worked of those considered working is calculated. This is based on number of days spent working (in intensity
 terms) in each activity and the assumption made below about hours constituting a full and half intensity day. *;

* Assumption on how many hours constitute full intensity. *;
scalar full_day_hours=8;

*Assumption on how many hours constitute a half intensity day. *;
scalar half_day_hours=2.5;

* The data here is at the daily level with a`i' representing  intensity of activity in day 'i'. The 'hrs_wrk' variable which
is generated represents hours which count towards hours worked for a particular day. *;

forvalues i=1/7{;

gen full_day_`i'=1*working if a`i'==10;
gen half_day_`i'=1*working/2 if a`i'==5;

*gen hrs_wrk_`i'=0;

*replace hrs_wrk_`i'=working*full_day if a`i'==10;

*replace hrs_wrk_`i'=working*half_day if a`i'==5;

};


egen full_days=rsum(full_day_*);
egen half_days=rsum(half_day_*);

egen full_days_total=total(full_days),by(hhid srl_n_m);
egen half_days_total=total(half_days),by(hhid srl_n_m);

egen total_days_worked=rsum(full_days_total half_days_total);

gen hrs_week=0;


replace hrs_week=full_days_total*full_day_hours + half_days_total*2*half_day_hours 												       if total_days_worked<=5;
replace hrs_week=5*full_day_hours 			  + (full_days_total-5)*(full_day_hours/2) 	+ half_days_total*2*(half_day_hours/2) 		   if total_days_worked>5&full_days_total>=5;
replace hrs_week=4*full_day_hours 			  + (5-4)*2*(half_day_hours) 	  			    + (half_days_total-(5-4))*2*(half_day_hours/2)   if total_days_worked>5&full_days_total==4;
replace hrs_week=3*full_day_hours 		      + (5-3)*2*(half_day_hours) 				    + (half_days_total-(5-3))*2*(half_day_hours/2)   if total_days_worked>5&full_days_total==3;
replace hrs_week=2*full_day_hours 		      + (5-2)*2*(half_day_hours) 		 		    + (half_days_total-(5-2))*2*(half_day_hours/2)   if total_days_worked>5&full_days_total==2;
replace hrs_week=1*full_day_hours 		      + (5-1)*2*(half_day_hours) 				    + (half_days_total-(5-1))*2*(half_day_hours/2)   if total_days_worked>5&full_days_total==1;
replace hrs_week=0*full_day_hours 		      + (5-0)*2*(half_day_hours) 				    + (half_days_total-(5-0))*2*(half_day_hours/2)   if total_days_worked>5&full_days_total==0;


*gen hrs_week=hrs_wrk_1+hrs_wrk_2+hrs_wrk_3+hrs_wrk_4+hrs_wrk_5+hrs_wrk_6+hrs_wrk_7;

*drop  hrs_wrk_1 hrs_wrk_2 hrs_wrk_3 hrs_wrk_4 hrs_wrk_5 hrs_wrk_6 hrs_wrk_7;

* Generating hours worked in a month *;

gen hrs_month=hrs_week*52/12;
lab var hrs_month "Hours worked in a month";



******* Cleaning Up *******;

order hhid mult_comb srl_n_m age hhsz;
keep hhid mult_comb srl_n_m srl_n_a hrs_month hrs_week age hhsz;
sort hhid srl_n_m srl_n_a;
ren mult_comb mult_l;



******* Collapse out activity level. Will reduce data to HH-individual level *******;

collapse (mean)  mult_l= mult_l age=age  hhsz=hhsz hrs_week=hrs_week hrs_month=hrs_month, by ( hhid  srl_n_m);
*collapse (mean)  mult_l= mult_l age=age  hhsz=hhsz sum) hrs_week=hrs_week hrs_month=hrs_month, by ( hhid  srl_n_m);


gen leisure=(5840/12-hrs_month)/(5840/12);
lab var leisure "Leisure hours in a month (normalized)";

drop hrs_month;


sort hhid srl_n_m;

save "Rawls/final/india_83_r_leisure.dta", replace;


*log close;



***urban_38.do
******************************************************
**PROGRAM 3:   GENERATING URBAN DATA				**
******************************************************

#delimit ;
clear;
set mem 500m;

log using "Rawls/final/log/urban_38.smcl", replace;


*********** GENERATING LEISURE AND CONSUMPTION ******************;

*********** Urban Data - 38th Round - 1983 **********************;


***********EXPENDITURE USING SCHEDULE 1 *************************;

use "1/dl0114/dl0114u_l14.dta", clear;
* Data is a summary of all expenditure. However, the structure of the dataset is a little weird. Every hhid has multiple
observations with each observation having 7 itemcodes. Therfore, if a household consumes more than 7 broad categories, then
a new observation is started. The collapse command takes care of this in the end. *;

* We first generate variables for total expenditure (itemcode 31), household size (itemcode 32)and 
expenditure on durables (itemcode 29)*;

gen totexp=0;
gen hhsz=0;
gen durables=0;

forvalues i=1/7 {;

replace totexp=value`i' if itemcode`i'==31;
replace hhsz=value`i' if itemcode`i'==32;
replace durables=value`i' if itemcode`i'==29;

};



* Collapse out the multiple households *;

collapse (sum) totexp=totexp hhsz=hhsz durables=durables (mean) mult_comb=mult_comb, by(hhid);

* Removing durables *;
gen exp=totexp-durables;

drop if exp<=0;
*111 observations dropped *;

drop if hhsz==0;
* 7 observations dropped *;


keep hhid exp hhsz mult_comb;
ren mult_comb mult_c;
sort hhid;

save "Rawls/final/india_83_u_exp.dta", replace;

clear;



*********** LEISURE USING SCHEDULE 10 *************************;

use "10/d156a/d156au.dta", clear;

* SPECIALCODE=2: "When Daily Activity Status Code in block-5 is 01 to 82, one

           		consolidated record of all the daily activities the person

           		was engaged with, has been created with Special Code 2"
			These observations are dropped as we use the raw (unsummarized) data. *;

drop if specialcode==2;
*70001 observations dropped *;


******* Generating unique identifier *******;
gen double u_id=hhid*1000+ srl_n_m*10+ srl_n_a;
lab var u_id "Unique Identifier for HH-Individual-Activity data";

* There were a lot of problems with duplicates in this file. Going through the cleaning steps *;

duplicates tag u_id, gen(problem);
* There 186 duplicates at this stage. Furthermore, there are some observations with intensity days as 0. Those observations
which are duplicates and have intensity days as 0 are removed. *;

drop if problem>=1&tot_day==0;
* 67 observations are dropped *;

duplicates tag u_id, gen(problem1);
* There are 26 duplicates at this stage. All household who still have these duplicates are dropped *;

egen problem_hh=max(problem1), by(hhid);
drop if problem_hh>=1;
* 102 observation dropped *;




******* Generating Hours Worked Using Time Disposition Data************;


*** Assumption on what contributes towards hours worked. ***;

* In the base case, everyone with activity code less than 60 and equal to 93 is considered working. This corresponds to the
scalar 'employment_rule' taking value 1. If employment_rule takes value 2, then 93 is not considered to be working. *;

scalar employment_rule=2;

gen working=0;
lab var working "Those who are employed";

if employment_rule==1 {;
* Assign value one to the variable 'working' for all those deemed to be working *;
replace working=1 if status_da<60|status_da==93;
};
else {;
replace working=1 if status_da<60;
};



* The hours worked of those considered working is calculated. This is based on number of days spent working (in intensity
 terms) in each activity and the assumption made below about hours constituting a full and half intensity day. *;

* Assumption on how many hours constitute full intensity. *;
scalar full_day_hours=8;

*Assumption on how many hours constitute a half intensity day. *;
scalar half_day_hours=2.5;

* The data here is at the daily level with a`i' representing  intensity of activity in day 'i'. The 'hrs_wrk' variable which
is generated represents hours which count towards hours worked for a particular day. *;

forvalues i=1/7{;

gen full_day_`i'=1*working if a`i'==10;
gen half_day_`i'=1*working/2 if a`i'==5;

*gen hrs_wrk_`i'=0;

*replace hrs_wrk_`i'=working*full_day if a`i'==10;

*replace hrs_wrk_`i'=working*half_day if a`i'==5;

};


egen full_days=rsum(full_day_*);
egen half_days=rsum(half_day_*);

egen full_days_total=total(full_days),by(hhid srl_n_m);
egen half_days_total=total(half_days),by(hhid srl_n_m);

egen total_days_worked=rsum(full_days_total half_days_total);

gen hrs_week=0;


replace hrs_week=full_days_total*full_day_hours + half_days_total*2*half_day_hours 												       if total_days_worked<=5;
replace hrs_week=5*full_day_hours 			  + (full_days_total-5)*(full_day_hours/2) 	+ half_days_total*2*(half_day_hours/2) 		   if total_days_worked>5&full_days_total>=5;
replace hrs_week=4*full_day_hours 			  + (5-4)*2*(half_day_hours) 	  			    + (half_days_total-(5-4))*2*(half_day_hours/2)   if total_days_worked>5&full_days_total==4;
replace hrs_week=3*full_day_hours 		      + (5-3)*2*(half_day_hours) 				    + (half_days_total-(5-3))*2*(half_day_hours/2)   if total_days_worked>5&full_days_total==3;
replace hrs_week=2*full_day_hours 		      + (5-2)*2*(half_day_hours) 		 		    + (half_days_total-(5-2))*2*(half_day_hours/2)   if total_days_worked>5&full_days_total==2;
replace hrs_week=1*full_day_hours 		      + (5-1)*2*(half_day_hours) 				    + (half_days_total-(5-1))*2*(half_day_hours/2)   if total_days_worked>5&full_days_total==1;
replace hrs_week=0*full_day_hours 		      + (5-0)*2*(half_day_hours) 				    + (half_days_total-(5-0))*2*(half_day_hours/2)   if total_days_worked>5&full_days_total==0;


*gen hrs_week=hrs_wrk_1+hrs_wrk_2+hrs_wrk_3+hrs_wrk_4+hrs_wrk_5+hrs_wrk_6+hrs_wrk_7;

*drop  hrs_wrk_1 hrs_wrk_2 hrs_wrk_3 hrs_wrk_4 hrs_wrk_5 hrs_wrk_6 hrs_wrk_7;

* Generating hours worked in a month *;

gen hrs_month=hrs_week*52/12;
lab var hrs_month "Hours worked in a month";



******* Cleaning Up *******;

order hhid mult_comb srl_n_m age hhsz;
keep hhid mult_comb srl_n_m srl_n_a hrs_month hrs_week age hhsz;
sort hhid srl_n_m srl_n_a;
ren mult_comb mult_l;



******* Collapse out activity level. Will reduce data to HH-individual level *******;

collapse (mean)  mult_l= mult_l age=age  hhsz=hhsz hrs_week=hrs_week hrs_month=hrs_month, by ( hhid  srl_n_m);
*collapse (mean)  mult_l= mult_l age=age  hhsz=hhsz sum) hrs_week=hrs_week hrs_month=hrs_month, by ( hhid  srl_n_m);


gen leisure=(5840/12-hrs_month)/(5840/12);
lab var leisure "Leisure hours in a month (normalized)";

drop hrs_month;

sort hhid srl_n_m;

save "Rawls/final/india_83_u_leisure.dta", replace;


log close;






*** ind_83_gendata.do;
******************************************************;
**PROGRAM 4:   COMBINING RURAL AND URBAN			**;
******************************************************;

**** COMBINING RURAL AND URBAN DATSETS ******;

use "Rawls/final/india_83_r_exp.dta",clear;

append using "Rawls/final/india_83_u_exp.dta";

sort hhid;
su mult_c;
gen weight_c=mult_c/r(sum);
ren hhsz hhsize;


save "Rawls/final/india_83_exp.dta",replace;

use "Rawls/final/india_83_r_leisure.dta",clear;

append using "Rawls/final/india_83_u_leisure.dta";

sort hhid srl_n_m;
su mult_l;
gen weight=mult_l/r(sum);
ren hhsz hhsize;

drop if age==.;
* 193 observations dropped;


save "/Users/xurui/Dropbox/Beyond_GDP/IND/CFE Labor/1983/ind_83_leisure.dta",replace;


******* GENERATING THE MATCHED DATASET USED TO DO CONSUMPTION CALCULATIONS *******;

clear
*set mem 200m

use "Rawls/final/matching/38/comb_match_hh.dta", clear
** This file contains a variable match_hh which takes value 1 for those households which have the same household
** id and also the same houshold characteristics like hhsize, religion etc

keep hhid match_hh

sort hhid

merge hhid using "Rawls/final/india_83_exp.dta"


drop if _merge!=3

* 117 obs dropped. All were present in the combined file but not in the exp file. 

keep hhid match_hh exp weight_c mult_c

sort hhid

merge hhid using "Rawls/final/india_83_leisure.dta"

drop if _merge!=3

* 854 obs dropped

drop if match_hh!=1

* 223765 obs dropped.

* abt 60% matched 

su weight
replace weight=weight/r(sum)

su weight_c
replace weight_c=weight_c/r(sum)

drop if age==.
* 89 observations dropped

keep hhid srl_n_m exp mult_c weight_c age hhsize

*** Generating pcode ***
sort hhid age
egen highest_age=max(age),by(hhid)
gen eldest=1 if highest_age==age
gen pcode=1 if eldest==1
* At this stage, pcode can take value 1 for more than one person in each household if there is more than one 
* person in the house who has the same highest age
by hhid:gen eldest_1=sum(eldest)
replace pcode=0 if eldest_1>1|pcode==.
* Now pcode takes value 1 only for 1 person in each household. 
* there are 78 households in which the eldest person is less than 10 yrs old. 3 household in which eldest person is
* less than 5 years old
drop  highest_age eldest eldest_1

sort hhid srl_n_m

save "/Users/xurui/Dropbox/Beyond_GDP/IND/CFE Labor/1983/ind_83_exp.dta", replace


