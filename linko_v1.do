clear
local POLL="PM2.5 PM10 SO2 NO2"
local value="avg max"
log using "D:\User_Data\Desktop\kriging\linko_data\\month_avg_regression_result_without_outlier_linko.log", replace
foreach poll of local POLL{
    foreach v of local value{
clear
set more off
set linesize 255
cap log c

cd "D:\User_Data\Desktop\kriging"
display "---------------------Daily `v' of `poll'------------------------------"
use "D:\User_Data\Desktop\kriging\linko_data\\`poll'_`v'_kriging_2000_2021.dta" ,clear


//keep if _merge==3



//handling date and month
tostring(date),replace
qui gen year=substr(date,1,4)
qui gen R=date(date,"YMD")
qui gen month=month(R)
qui tostring(month),gen(str_month)
qui gen monthly=year+"m"+str_month
qui gen month_R=monthly(monthly,"YM")

//filter linko power station <=50 km
geodist 25.1208 121.2983 y x,generate(num_distance_linko)
geodist 24.1618378 120.6446744 y x, generate(num_distance_taichung)
geodist 22.6614546 120.2821877 y x, generate(num_distance_kaohsiung)
keep if num_distance_linko<=50 | num_distance_taichung<=50 | num_distance_kaohsiung<=50




gen R2010=date("2010101","YMD")
drop if R<R2010


//eliminate outlier
egen p1p=pctile(predicted_value),p(1)
egen p99p=pctile(predicted_value),p(99)
drop if predicted_value<p1p | predicted_value>p99p

	//generate dummy variables
qui gen D2014=1 if month_R>monthly("2014m9","YM")
qui replace D2014=0 if missing(D2014)
qui gen D2016=1 if month_R>monthly("2016m10","YM")
qui replace D2016=0 if missing(D2016)
qui gen DLinko=1 if num_distance_linko<=50
qui replace DLinko=0 if missing(DLinko)
qui gen D14L=D2014*DLinko
qui gen D16L=D2016*DLinko

//get coordinate for absorb
qui gen string_x=string(x)
qui gen string_y=string(y)
qui egen coordinate=concat(string_x string_y),punct(" ")

//get monthly average

qui egen month_avg_p=mean(predicted_value), by(month_R coordinate)
qui gen log_month_avg_p=log(month_avg_p)

//qui gen log_predicted_value=log(predicted_value)
//Label each variable
//label variable R "date since 2007/9/30"

label variable D2014 "1 if date>2014/08/31 0 otherwise"
label variable D2016 "1 if date>2016/10/06 0 otherwise"
label variable DLinko "1 if numerial distance to Linko Power Station<=50"
label variable D14L "Dlinko*D2014"
label variable D14L "Dlinko*D2016"
label variable coordinate "string coordinate"
save "`poll'_`v'_month_avg_linko.dta", replace
preserve

keep month_avg_p log_month_avg_p month_R D2014 D2016 DLinko D14L D16L coordinate
duplicates drop month_R coordinate, force  
regress month_avg_p month_R D2014 D2016 DLink D14L D16L,absorb(coordinate)
regress log_month_avg_p month_R D2014 D2016 DLink D14L D16L,absorb(coordinate)

restore

	}
}
log close
    
