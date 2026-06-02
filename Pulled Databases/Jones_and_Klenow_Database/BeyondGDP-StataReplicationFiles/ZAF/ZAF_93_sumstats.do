********************************************************
**PROGRAM 1: GENERATING COUNTRY DATASET COUNTRY_YR.DTA**
********************************************************

set type double
cd "C:\Users\Rui\Dropbox\Beyond_GDP\ZAF"
* Open cleaned HH roster
use "M8_HROST.dta", clear
*use "C:\Users\klenow.ECON\Documents\Beyond GDP\ZAF\M8_HROST.dta", clear

* Drop all non-residents in HH (variable "mcode": 1a, circled member/resident. Not sure what circled member means.. ?? 3627 dropped)
* Drop all obs with negative age (288 dropped)
* keep relevant variables: household ID number, person code, is person respondent, relationship to head, age in years, education, gender, cluster number
* rename variables: education and cluster number
* sort person code for tied values of Household ID
* Drop all non-residents in HH, all obs with negative age, keep relevant variables, rename vars

*outsheet hhid pcode mcode age hours_wo using ZAF_93.csv , comma replace

drop if mcode!=1

** [Rui: create hhsize after dropping non-residents in HH but before dropping obsv based on age
sort hhid
by hhid: gen hhsize=_N

drop if age <= 0 
*497 observations dropped with age<0, 498 dropped with age<=0
drop if age > 100
drop if age==.

qui {
keep hhid pcode pers_res rel_head age educ_c gender_n clustnum hhsize
rename gender_n gender
rename educ_c educ
rename clustnum cluster
sort hhid age
}

* Create hhsize variable (Household Size) determined by number of observations for each Household ID
qui {
lab var hhid "Household Size"
order hhid pcode hhsize age gender educ
sort hhid

save "ZAF_93.dta", replace
*save "C:\Users\klenow.ECON\Documents\Beyond GDP\ZAF\ZAF_93.dta", replace
}

*Bring in weights
use "STRATA2.DTA", clear
*use "C:\Users\klenow.ECON\Documents\Beyond GDP\ZAF\STRATA2.DTA", clear
sort hhid
merge 1:m hhid using "ZAF_93.dta"
*merge 1:m hhid using "C:\Users\klenow.ECON\Documents\Beyond GDP\ZAF\ZAF_93.dta"
drop _m lang_ type metro prov newprov sweight
sort hhid pcode hhsize
save "ZAF_93.dta", replace
*save "C:\Users\klenow.ECON\Documents\Beyond GDP\ZAF\ZAF_93.dta", replace

** Bring in constructed HH expenditure, defined as [Total Monthly Expenditure] - [monthly savings]
* Open constructed HH monthly expenditure
qui {
use "HHEXPTL.DTA", clear
*use "C:\Users\klenow.ECON\Documents\Beyond GDP\ZAF\HHEXPTL.DTA", clear

* hhexp includes: housing, utilities, food, clothing, health care, insurance, 
*                 schooling, child care, transportation
* hhexp excludes: savings, remittances, durables
gen hhexp=totmexp-mxsav //remove savings
lab var hhexp "HH Total Monthly Expenditure"

keep hhid hhexp clustnum
sort hhid
merge 1:m hhid using "ZAF_93.dta"
*merge 1:m hhid using "C:\Users\klenow.ECON\Documents\Beyond GDP\ZAF\ZAF_93.dta"
order hhid pcode hhsize age hhexp rcweight 
sort hhid pcode
drop _merge
keep if hhsize~=.
save "ZAF_93.dta", replace
*save "C:\Users\klenow.ECON\Documents\Beyond GDP\ZAF\ZAF_93.dta", replace
}

*bring in income for comparison
*Open constructed HH monthly income
*hhinc includes: rent  income, remittances, regular wage income, 
*	first casual income, second casual income,  agricultural  income, 
*	self-employment income, housing/food support if needed
qui {
use "HHINCTL.DTA", clear
*use "C:\Users\klenow.ECON\Documents\Beyond GDP\ZAF\HHINCTL.DTA", clear
rename totminc hhinc
keep hhid hhinc
sort hhid
merge 1:m hhid using "ZAF_93.dta"
*merge 1:m hhid using "C:\Users\klenow.ECON\Documents\Beyond GDP\ZAF\ZAF_93.dta"
order hhid pcode hhsize age hhexp hhinc rcweight
sort hhid hhsize
drop _merge
keep if hhsize~=.
save "ZAF_93.dta", replace
*save "C:\Users\klenow.ECON\Documents\Beyond GDP\ZAF\ZAF_93.dta", replace
}

**Compute monthly individual hrs worked from weekly hours worked

*quietly {
use "M8_EMPS.dta", clear
*use "C:\Users\klenow.ECON\Documents\Beyond GDP\ZAF\M8_EMPS.dta", clear
keep hhid pcode hours_wo
gen mohours=hours_wo*(52/12) //changed to monthly hours worked = weekly hours worked*(52/12), from weekly hours worked*(4.5)
lab var mohours "Monthly Hours Worked"
sort hhid pcode
*duplicates list hhid pcode 
duplicates drop hhid pcode , force
merge 1:1 hhid pcode using "ZAF_93.dta"
*merge 1:1 hhid pcode using "C:\Users\klenow.ECON\Documents\Beyond GDP\ZAF\ZAF_93.dta"
drop _merge
*}

outsheet hhid pcode mohours hhexp hhinc using ZAF_93.csv , comma replace

drop if mohours<0 //drop negative labor hours (118 dropped)
drop if hhexp==. // drop obs with missing expenditures values 
drop if hhinc==. //drop obs with missing income values 

quietly {
sort hhid pcode
gen hrs_mon=0
replace hrs_mon=mohours if mohours<.
}
drop if hrs_mon>=(5840/12) //drop extreme values exceeding maximum available monthly working hrs
quietly {
gen leisure=(5840/12-hrs_mon)/(5840/12) // 16*365=5840, yearly hrs available given 8hrs sleep
gen wave=1993
lab var leisure "Total Monthly Leisure Hours"
* there are 3 obs with hhinc<0, make sure to drop them when want log income later
order hhid pcode wave hhsize age hhexp hhinc leisure rcweight pers_res rel_head hrs_mon educ
sort hhid pcode wave
save "ZAF_93.dta", replace
*save "C:\Users\klenow.ECON\Documents\Beyond GDP\ZAF\ZAF_93.dta", replace
}

*Use Census raised weight (rcweight) rather than Enumerated raised weight (rsweight). Census raised weights are 
*	considered accurate at the aggregate level. Census raised weights deviate from enumerated raised weights 
*	"where the provincial breakdown is concerned" (pg 9)
*	From LSMS OVERVIEW OF THE SOUTH AFRICA INTEGRATED HOUSEHOLD SURVEY, page 8: "The census population for the survey 
*	data was estimated by applying Sadie's population growth rates to the adjusted 1991 census figures...This implies 
*	that a raising factor of 891.4154 (40.1 million divided by an expected take of 45,000) should be applied to the 
*	results weighted by enumeration to obtain the population it represents"


svyset [pweight=rcweight]
*svymean hhsize age hhexp hhinc leisure  // Stata 10 format
svy: mean hhsize age hhexp hhinc leisure  // Stata 11 format

*normalize weights to sum to 1
summ rcweight
gen weight=rcweight/r(sum)
lab var weight "Normalized Individual Weight"

keep hhid hhsize age hhexp leisure weight 
order hhid hhsize age hhexp leisure weight
save "ZAF_93.dta", replace
*save "C:\Users\klenow.ECON\Documents\Beyond GDP\ZAF\ZAF_93", replace
describe
summarize
*list

format hhexp %18.10f leisure %14.11f weight %11.4e 

outfile using "ZAF_93.txt" , wide replace
*outsheet hhid pcode age hhexp leisure weight hhinc hhsize using ZAF_93.csv , comma replace


exit

*Note: The following is not part of PROGRAM 1.  This is included only
* to provide background on how household expenditure was calculated.

==========================
SAMPLE TOTAL HH EXPENDITURE CALC
===========================

#delimit ;

log using do\clcexptl,replace;
set log linesize 200;

*************************************************************;
*                                                           *;
*    Name    : CLCEXPTL.DO              V : 01              *;
*    Date    : AUGUST 5, 1994                               *;
*    Infile  : S4_HDEF,and other Expenditure files          *;
*    Outfile : HHEXPTL                                      *;
*                                                           *;
*    OBJECTIVE: Sum the components of Expenditure           *;
*               Calculate total monthly Expenditure         *;
*                                                           *;
*************************************************************;

clear;
set more 1;

** SET THE FILE   **
;
use s4_hdef;
keep hhid;
lab data "Total Month Expenditure";
sort hhid;
save hhexptl,replace;

** REMEMBER: Files are not same dimension.  
             After each merge legimate zeros have to be set
             to zeros and some apparent zeros to missing 
             if it has not beeing done in particular program in that
             section.  The markers relative to each imported file
             reports the number of original values, imputed values and
             of remaining missing values.
;

** Bring in HOUSING EXPENDITURE which includes rental expenses   
   and Imputed Value of rent calculated using value of housing   
   In household level file HHEXP04 created using CLCEXP04.DO     
;
use hhexp04;
keep hhid marker04 mxtrent;
sort hhid;
save stext1,replace;

use hhexptl;
merge hhid using stext1;
tab _merge;
drop _merge;
sort hhid;
save,replace;
!del stext1.dta;


** Bring in UTILITIES EXPENDITURES                               *
   in household level file HHEXP06 created using CLCEXP06.DO     *
   Missing: There are ~600 that do not spend on Utilities that   *
   have been set to zero.                                        *
   Note: Included in the values are some imputed estimates of    *
   the value of wood collected using a value of R2 per person    *
   per trip.
;
use hhexp06;
keep hhid marker06 mxtutil;
sort hhid;
save stext1,replace;

use hhexptl;
merge hhid using stext1;
tab _merge;
drop _merge;
sort hhid;
save,replace;
!del stext1.dta;


** Bring in FOOD EXPENDITURE                                       *
   in household level file HHEXP07 created using CLCEXP07.DO       *
   Missing: There are ~160 that do not spend on Food that have     *
   been left to missing.  Some will be recuperated later with      * 
   the values of wages paid in food - Marker07 has the housheolds  *
;
use hhexp07;
keep hhid marker07 mxtfood;
sort hhid;
save stext1,replace;

use hhexptl;
merge hhid using stext1;
tab _merge;
drop _merge;
sort hhid;
save,replace;
!del stext1.dta;


** Bring in REGULAR NON FOOD EXPENDITURE                          *
   in household level file HHEXP08 created using CLCEXP08.DO      *
   Missing: There are ~64 that do not spend anything and that for *
   now have been set to zero - The marker08 has the housheolds    *
;
use hhexp08;
gen mxper= mxcig+mxalc+mxent+mxpcare+mxnews+mxtel;
lab var mxper "Personal Items";
gen mxoth1= mxwash+mxdues+mxdon+mxhelp;
lab var mxoth1 "Other NonFood 1";
keep hhid mxper mxcar mxtran mxchil mxoth1 mark;
sort hhid;
save stext1,replace;

use hhexptl;
merge hhid using stext1;
tab _merge;
drop _merge;
sort hhid;
save,replace;
!del stext1.dta;


** Bring in OCCASIONAL NON FOOD EXPENDITURE                        *
   in household level file HHEXP09 created using CLCEXP09.DO       *
   Missing: There are ~748 that do not spend anything and that for *
   now have been set to zero - Marker09 has the list               *
;
use hhexp09;
gen mxhous = mxkit + mxbed;
lab var mxhous "Household Exp.";
gen mxcloth = mxshoe+mxclth+mxcmat;
lab var mxcloth "Clothing Exp.";
gen mxhea = mxdoc + mxhfee + mxmedsp + mxtrad;
lab var mxhea "Health Care Exp.";
gen mxoth2 = mxholi + mxlux;
lab var mxoth2 "Other NonFood 2";

keep hhid marker09 mxhous mxcloth mxhea mxoth2;
sort hhid;
save stext1,replace;

use hhexptl;
merge hhid using stext1;
tab _merge;
drop _merge;
sort hhid;
save,replace;
!del stext1.dta;


** Bring in Some of the TOTAL SUMMARY EXPENDITURE                  *
   in household level file HHSTX01 created using CALCSTX1.DO       *
   Missing: There are 36 HHs that do not spend anything and that   *
   for now have been set to zero.  This is justified since households 
   in the same cluster do not spend anything on those items -      *
   Marker10 has the list of original missings                      *
;
use hhstx01;
rename stxinsur mxinsur;
rename stxsav mxsav;

keep hhid marker10 mxinsur mxsav;
replace mxinsur=0 if mxinsur==.;
replace mxsav=0 if mxsav==.;
sort hhid;
save stext1,replace;

use hhexptl;
merge hhid using stext1;
tab _merge;
drop _merge;
sort hhid;
save,replace;
!del stext1.dta;


** Bring in SCHOOLING EXPENDITURE                                     *
   in household level file HHEXP14 created using CLCEXP14.DO          *
   Missing: There are 5457 household that spend on Schooling          *
   Everybody else has been set to zero - Marker14 has the list        *
;
use hhexp14;
keep hhid marker14 mxtsch;
sort hhid;
save stext1,replace;

use hhexptl;
merge hhid using stext1;
tab _merge;
drop _merge;
sort hhid;
save,replace;
!del stext1.dta;


** Bring in REMITTANCE EXPENDITURE                                 *
   in household level file HHEXP17 created using CLCEXP17.DO       *
   Missing: There are 1462 Households that report Remittance       *
   Expenditure. Everybody else has been set to zero                * 
   There are 26 true missing values, that have been set to Missing *
;
use hhexp17;
keep hhid marker17 mxtrem;
sort hhid;
save stext1,replace;

use hhexptl;
merge hhid using stext1;
tab _merge;
drop _merge;
sort hhid;
save,replace;
!del stext1.dta;


*** Correct for mis-allocated CHILD CARE SUPPORT.  In same cases it was
    noted that households had childcare expenses and yet were single 
    people households.  In this sections they are reclassified as remittances
    as long as the values are larger than the single value (~73 cases).  
    In all the other cases when hhsize is larger than one childcare is added 
    to other regular non food expenses
;
use hhexptl;
merge hhid using hhsize;
tab _merge;
drop _merge;
sort hhid;

replace mxoth1=mxoth1 + mxchil if mxchil>=0 & hhsizem>1;
replace mxtrem=mxtrem + mxchil if mxchil>=0 & hhsizem==1 & mxtrem<mxchil;
replace mxtrem=mxchil if mxchil>=0 & hhsizem==1 & mxtrem==1;

save,replace;

*** ADD OTHER IMPUTED COMPONENTS OF TOTAL EXPENDITURE   ***;


** Add HOUSING SUPPORT if needed - See explanation below        **
   
   It is possible that the household does not own the house and that does
   not pay any rent, or that he receives a subsidy for the house payment.
   We estimated, in any case, the value of rent if there is no values 
   reported or if the house is owned.  But if the household receives 
   some housing benefit we could underestimate the value of housing. 
   The value of housing subsidy is derived from HHINC21 estimated by 
   CLCINC21.DO.
;
use hhinc21;                 
keep hhid homewage ;
keep if homewage>0 & homewage~=.;
sort hhid;
save houstemp,replace;

use hhexptl;
merge hhid using houstemp;
tab _merge;
drop _merge;
replace homewage=0 if homewage==.;

** Case 1: Household pays for rent and still receives a subsidy.
           The value of subsidy should be added to the actual
           expenditure (~71 cases).
;
replace mxtrent=mxtrent + homewage if marker04==1 & homewage>0;

** Case 2: Households gives an estimated market value for rent provided 
           by the employer or receives a subsidy for loan payments and 
           the figure reported in the employment section is higher
;
replace mxtrent=homewage if homewage>0 & homewage>mxtrent |
                            homewage>0 & mxtrent==. ;
!del housetemp.dta;
sort hhid;
save hhexptl,replace;


** Add FOOD SUPPORT if needed - See explanation below        **
   
   It is possible that the household receives some food subsidy from the
   employer, or that he receives some remittances in kind.  Those amounts 
   were supposed to be recorded in the food consumption section as
   food received from other sources (FOS).  In this section we will add the
   value of the food subsidy from wages that has not been reported in the 
   food section and also the value of remittances in kind.  Here we assume 
   that all remittances in kind are given in form of food.  It is possible 
   that some are clothes, but it is less likely.
   The value of food subsidy is derived from HHINC21, HHINC22, HHINC23 that
   were estimated by CLCINC21.DO, CLCINC22.DO and CLCINC23.DO. The remittances
   in kind are derived from HHINC16 estimated by HHINC16.
;
use hhsize;
keep hhid;
merge hhid using hhinc21;                 
keep hhid foodwage ;
sort hhid;
merge hhid using hhinc22;
keep hhid foodwage foodcw1;
sort hhid;
merge hhid using hhinc23;
keep hhid foodwage foodcw1 foodcw2;
sort hhid;
merge hhid using hhinc16;
keep hhid foodwage foodcw1 foodcw2 totm_kin;
sort hhid;
egen foodrec=rsum(foodwage foodcw1 foodcw2 totm_kin);
lab var foodrec "Total Month Food Received";
merge hhid using hhfexpt;

gen flgfrec1=0;
lab var flgfrec1 "Flag Food Received Wage";
replace flgf=1 if (foodwage>0 & foodwage~=.) |
                  (foodcw1>0 & foodcw1~=.)   |          
                  (foodcw2>0 & foodcw2~=.)  ;           
gen flgfrec2=0;
lab var flgfrec2 "Flag Food Received Remittances";
replace flgfrec2=1 if totm_kin>0 & totm_kin~=.;
gen flgfrec3=0;
lab var flgfrec3 "Flag Food Received F.O.S";
replace flgfrec3=1 if tmxrec>0 & tmxrec~=.;

keep hhid foodrec tmxrec flgf*;
sort hhid;
save tmpfood,replace;

use hhexptl;
merge hhid using tmpfood;
tab _merge;
drop _merge;
replace foodrec=0 if foodrec==.;
replace tmxrec=0  if tmxrec==.;

** Case 1: Amount of food received is larger that Food from other Sources.
           The difference should be added to the total food expenditure 
           (~129 cases).
;
replace mxtfood=mxtfood + foodrec if foodrec>tmxrec & tmxrec>0;

** Case 2: Amount of food received is positive and Food from other Sources
           is equal to zero. Food received should be added to the total food 
           expenditure (~1282 cases), or substituted to it if no food 
           expenditure is reported (~122 cases);
;
replace mxtfood = mxtfood + foodrec if foodrec>0 & tmxrec==0;
replace mxtfood = foodrec if foodrec>0 & mxtfood==.;

!del tmpfood.dta;
sort hhid;
save hhexptl,replace;

** Add SCHOOL BURSARY and SCHOOL MEALS if needed - See explanation below        **
   
   There are approximately 129 households that report positive 
   values of annual school bursaries. These values are added to the
   the school expenses.

   There are 114 households that report receiving school meals.
   From the descriptive statistics, though, the time reference 
   used is not clear.  Therefore school meals have not been included
   in the calculation of total expenditure.
;
use s1_ed2;                 
keep hhid bursary1;
keep if bursary1>0 & bursary1~=.;
sort hhid;
save burstemp,replace;

use hhexptl;
merge hhid using burstemp;
tab _merge;
drop _merge;
replace bursary=0 if bursary==.;

replace mxtsch = mxtsch + bursary/12 if bursary>0 & mxtsch~=.;
replace mxtsch = bursary/12 if bursary>0 & mxtsch==.;

!del burstemp.dta;
sort hhid;
save hhexptl,replace;


** Add TRANSPORT COST if needed - See explanation below        **

   Transport cost is reported as an item of regular food expenditure.
   In addition it was asked the weekly cost of transport for School
   (S5.Q7) and the daily cost of transport for work (S8.4Q4).
   It is possible that all or part of the transportation expenditure 
   for school and work are not reported in the regular non food expenses.  
   Therefore we want to add the difference to the montly transport 
   expenses. 
   The Transport files TRSCH1 and TRWK1 have been created using 
   file CLCEXPTR.DO.  Imputed values are reported in the markert1 and 2.
   
   In addition we want to add the value of the transport benefits 
   received from the employer.  In this case they should have not been
   reported in any other section of the questionnaire (and if they had
   been reported it would still be impossible to separate the expenses
   for own use and for work).  The values are derived from HHINC21, 
   estimated using CLCINC21.DO.
;

use hhexptl;
merge hhid using trsch1;
tab _merge;
drop _merge;
sort hhid;
merge hhid using trwk1;
list if _merge==2;
tab _merge;
list if _merge==2;
drop if _merge==2;
drop _merge;

replace trsch=0   if trsch==.;
replace trwork=0  if trwork==.;

gen trschwk = trsch + trwork;

count if trschw>0 & mxtran>0 & trschw>mxtran;

** Case 1: Amount of transport form school and work is larger than values
           in regular non food expenditure.
           The difference should be added to travel expenditure (~96 cases).
;
replace mxtran = trschw if trschw>0 & mxtran>0 & trschw>mxtran;;

count if trschw>0 & (mxtran==0 | mxtran==.);


** Case 2: Amount of transport form school and work is positive and
           amount in non food regular expenditure is equal to zero or
           missing.  The amount should be substituted to travel 
           expenditure (~1397 Cases).
;
replace mxtran = trschw if trschw>0 & (mxtran==0 | mxtran==.);
sort hhid;
save hhexptl,replace;

** Case 3: The household receives some contribution for transport from   
           the employer. Values are added to the travel expenditure
           (~694 Cases);
use hhinc21;
keep hhid travwage;
keep if trav>0;
sort hhid;
save sttw1,replace;

use hhexptl;
merge hhid using sttw1;
!del sttw1.dta;
tab _merge;
drop _merge;
replace mxtran = mxtran + travwage  if travwage>0 & travwage~=.;
sort hhid;
save hhexptl,replace;


** Add DURABLE and TAX EXPENSES if needed - See explanation below        **
   
   Information on durable expenses and hire purchases are available 
   in different sections of the questionniare.  

              Occasional food spending: S4.2Q1 codes 2 and 4
              Summary expenditure: S4.3Q3 codes 4 and 5   
              Debt: S4.5Q2c code 10

   These values have not been included in the calculation of total 
   expenditure because in theory, the current expenditure for 
   durables includes the cost of hire purchases (Interest included
   or not) and the depreciated value of the expenses for durables
   occurred in the last few years.  Since we only have the values of 
   hire purchases and values of lump purchases of furniture, home
   repairs and car leases, we would create a discrepancy between 
   these households and those richer household that purchased their
   durables in cash or in the previous year.

   The only information on taxes is available for dependent wage work in 
   S8.2.3Q4d-Q4f. In that case income has been calculated using NET WAGES.  
   It remains that other forms of income may include tax liabilities: both
   personal and property taxes.  In the calculation of expenditure taxes
   were not used al all.
   
   It remains that the values of expenditure calculated in this program 
   refer only to CURRENT EXPENDITURE NET OF TAXES, therefore it is expected 
   to be LOWER than INCOME for these households.  The difference being the 
   depriciated value of their durables and all forms of taxes liabilities
   included in the income received. 
; 

**   ---------------------- TOTALS ---------------------------   **
**  Add all the pieces together to calculate the total household **
**  montly income                                                **
*******************************************************************
;
gen totmexp = 
     mxtrent + 
     mxtutil + 
     mxtfood + 
     mxper  + mxcar + mxtran + mxoth1  + 
     mxhous + mxcloth + mxhea + mxoth2 + 
     mxinsur + mxsav +
     mxtsch + 
     mxtrem;

lab var totmexp "Total Monthy Expenditure";
sort hhid;
drop mxchil;
save hhexptl,replace;

sum mx* tot;
sum totmexp if totmexp>=0,det;

****--------END--------;
log close;

==========================
SAMPLE CALCULATING MONTHLY INCOME:
#delimit ;
===========================

log using do\clcinctl,replace;
set log linesize 200;

*************************************************************;
*                                                           *;
*    Name    : CLCINCTL.DO              V : 01              *;
*    Date    : MAY 30,1994                                  *;
*    Infile  : S2_HDEF,and other income files               *;
*    Outfile : hhinctl                                     *;
*                                                           *;
*    OBJECTIVE: Sum the components of Income                *;
*               Calculate total monthly income              *;
*                                                           *;
*************************************************************;

clear;
set more 1;
use s4_hdef;
keep hhid;
sort hhid;

** REMEMBER: Files are not same dimension.  
             After each merge We need to set legimate zeros 
             to that value and some apparent zeros to missing *;


** Bring in RENT INCOME and Imputed Value of Housing             *
   in household level file HHINC04 created using CLCINC04.DO     *
;

merge hhid using hhinc04;
tab _merge;
drop _merge;
replace imprent=0 if imprent==.;
replace rentinc=0 if rentinc==.;
replace farmrent=0 if farmrent==.;
replace liverent=0 if liverent==.;
sort hhid;
lab data "Total Income";
save hhinctl,replace;

** Bring in REMITTANCES                                          *
   in household level file HHINC16 created using CLC16V01.DO     *
;
use hhinc16;
keep hhid totm_cas totm_kin totm_rec;
sort hhid;
save step01,replace;

use hhinctl;
merge hhid using step01;
tab _merge;
drop _merge;
replace totm_rec=0 if totm_rec==.;
replace totm_kin=0 if totm_kin==.;
replace totm_rec=0 if totm_rec==.;
sort hhid;
save hhinctl, replace;


** Bring in REGULAR WAGE INCOME                                  *
   in household level file HHINC21 created using CLCINC21.DO     *
;
merge hhid using hhinc21;
tab _merge;
drop _merge;

replace marker21=0 if marker21==.;
replace hhnwage=0  if hhnwage==.  ;
replace hhnwage=.  if marker21>0  ;
replace hhgwage=0  if hhgwage==.;
replace hhgwage=.  if marker21>0  | hhgwage==0 & marker21>0;

replace travwage=0 if travwage==.;
replace travwage=. if marker21>0 ;

replace foodwage=0 if foodwage==.;
replace foodwage=. if marker21>0;
replace homewage=0 if homewage==.;
replace homewage=. if marker21>0;

sort hhid;
save hhinctl,replace;


** Bring in FIRST CASUAL INCOME                                  *
   in household level file HHINC22 created using CLCINC22.DO     *
;
merge hhid using hhinc22;
tab _merge;
drop _merge;

replace marker22=0 if marker22==.;
replace hhc1wage=0 if hhc1wage==.;
replace hhc1wage=. if marker22>0;
replace foodcw1=0 if foodcw1==.;
replace foodcw1=. if marker22>0;
replace bencw1=0 if bencw1==.;
replace bencw1=. if marker22>0;

sort hhid;
save hhinctl,replace;


** Bring in SECOND CASUAL INCOME                                 *
   in household level file HHINC23 created using CLCINC23.DO     *
;
merge hhid using hhinc23;
tab _merge;
drop _merge;

replace marker23=0 if marker23==.;
replace hhc2wage=0 if hhc2wage==.;
replace hhc2wage=. if marker23>0;
replace foodcw2=0 if foodcw2==.;
replace foodcw2=. if marker23>0;
replace bencw2=0 if bencw2==.;
replace bencw2=. if marker23>0;

sort hhid;
save hhinctl,replace;


** Bring in AGRICULTURAL INCOME                                  *
   in household level file HHINC25 created using CLCINC25.DO     *
;
merge hhid using hhinc25;
tab _merge;
drop _merge;
replace agincome=0 if agincome==. & largefrm~=1;
replace agsubsid=0 if agsubsid==.;
sort hhid;
save hhinctl,replace;


** Bring in SELF-EMPLOUMENT INCOME                               *
   in household level file HHINC31 created using CLCINC31.DO     *
;
merge hhid using hhinc31;
tab _merge;
drop _merge;

replace marker31=0 if marker31==.;
replace profit31=0 if profit31==.;
replace profit31=. if marker31>0;
sort hhid;
save hhinctl,replace;


** Bring in OTHER TRANSFERS (Ag. Subsidies are Already included) *
   in household level file HHINC32 created using CLCINC32.DO     *
;
merge hhid using hhinc32;
tab _merge;
drop _merge;

replace marker32=0 if marker32==.;
replace otherinc=0 if otherinc==.;
replace otherinc=. if marker32>0;
sort hhid;

** Take care of extremely long variables - To be done in the single files *
;
recast float _all;
recast long hhid;
recast int mark*;
sort hhid;

save hhinctl,replace;


**   Add VALUE OF FOOD SUPPORT - If needed           **

**   This step is needed to filter cases in which value of wages in
     kind was omitted in the regular wage section, or in the remittances 
     under the mistaken impression that it was doubling counting.
     Uses the file HHFEXPT calculated using CALCXT01.DO
;
merge hhid using hhfexpt;
tab _merge;
drop _merge;

drop tmxpur tmxpro tmxcon;

** Add to the wages for Foood if larger than subsidy and working 
;
replace foodwage=tmxrec if foodwage<tmxrec & totm_kin==0 & 
                           hhnwage>0   & tmxrec~=.               |
                           foodwage==. & totm_kin==0  & tmxrec~=.;

** Add to the remittances if not working and still larger that subsidy
;
replace totm_rec=totm_rec + tmxrec if foodwage<tmxrec & totm_kin==0  &
                                      hhnwage==0 & tmxrec~=.;
sort hhid;
save hhinctl,replace;

** Add HOUSING SUPPORT if needed - See explanation below        **
   
   It is possible that the household does rent the house but does
   not pay any rent.  In that case it is either and underestimation 
   of the value that he receives from the employer, if he is working, or
   from a relative if he is not working
;
use s4_hsv1;
keep hhid rent_mkt ;
keep if rent_mkt>0 & rent_mkt~=.;
sort hhid;
save houstemp,replace;

use hhinctl;
merge hhid using houstemp;
tab _merge;
drop _merge;

** Add to the wages for housing if larger that subsidy and working 
;
replace homewage=rent_mkt if homewage<rent_mkt & hhnwage>0 & rent_mkt~=. |
                             homewage==. & rent_mkt~=. ;

** Add to the remittances if not working and still larger that subsidy
;
replace totm_rec=totm_rec + rent_mkt if hhnwage==0 &
                                        homewage<rent_mkt & rent_mkt~=. ;

!del housetemp;


**   ---------------------- TOTALS ---------------------------   **
**  Add all the pieces together to calculate the total household 
    montly income                                                **
;
gen totminc = 
 imprent  + farmrent + liverent + rentinc +
 totm_rec + 
 hhnwage  + travwage + foodwage + homewage + 
 hhc1wage + foodcw1  + bencw1 + 
 hhc2wage + foodcw2  + bencw2 + 
 agincome + agsubsid + 
 otherinc + profit31
;
lab var totminc "Total Monthy Income";
sort hhid;
save hhinctl,replace;

sum totminc if totminc>=0,det;

*________________________________________________________;


keep    hhid 
        marker*
        imprent farmrent liverent rentinc 
        totm_rec totm_kin
        hhnwage hhgwage travwage homewage foodwage
        hhc1wage foodcw1 bencw1 
        hhc2wage foodcw2 bencw2 
        agincome agsubsid
        otherinc profit31
        totminc;  

order   hhid 
        marker*
        imprent farmrent liverent rentinc 
        totm_rec totm_kin
        hhnwage hhgwage travwage homewage foodwage
        hhc1wage foodcw1 bencw1 
        hhc2wage foodcw2 bencw2 
        agincome agsubsid
        otherinc profit31
        totminc;  

sort hhid;
save hhinctl,replace;

****--------END--------;
log close;
!del step01.dta;

