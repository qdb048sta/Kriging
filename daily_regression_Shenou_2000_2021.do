clear
local POLL="PM2.5 PM10 SO2 NO2"
local value="avg max"
cd "D:\User_Data\Desktop\kriging"
log using "D:\User_Data\Desktop\kriging\Shenou\result\daily_reg_2000-2016.log",replace
set more off
set linesize 255
cap log c
foreach poll of local POLL{
    foreach v of local value{


display "---------------------Daily `v' of `poll'------------------------------"
use "D:\User_Data\Desktop\kriging\Shenou\data\Python_kriging_data\dataset\\`poll'_`v'_kriging_2000_2021.dta" ,clear

//filter out only within target <=50km
geodist 25.1272 121.8156 y x,generate(num_distance_shenou)
geodist 24.1618378 120.6446744 y x, generate(num_distance_taichung)
geodist 22.6614546 120.2821877 y x, generate(num_distance_kaohsiung)
keep if num_distance_shenou<=50 | num_distance_taichung<=50 | num_distance_kaohsiung<=50



//handling date and month
tostring(date),replace
qui gen R=date(date,"YMD")

//eliminate outlier
if "`poll'"=="PM2.5"{
	gen R2006=date("20060101","YMD")
	drop if R<R2006
	drop R2006
}
if "`poll'"=="PM10"{
	gen R2006=date("20000101","YMD")
	drop if R<R2006
	drop R2006
}
if "`poll'"=="SO2"{
	gen R2006=date("20000101","YMD")
	drop if R<R2006
	drop R2006
}
if "`poll'"=="NO2"{
	gen R2006=date("20000101","YMD")
	drop if R<R2006
	drop R2006
}


egen p1p=pctile(predicted_value),p(1)
egen p99p=pctile(predicted_value),p(99)
drop if predicted_value<p1p | predicted_value>p99p
drop p1p p99p

	//generate dummy variables
qui gen D=1 if R>date("20070930","YM")
qui replace D=0 if missing(D)
qui gen shenou_dummy=1 if num_distance_shenou<=50
qui replace shenou_dummy=0 if missing(shenou_dummy)
qui gen Dshenou = D*shenou_dummy
//get coordinate for absorb
qui gen string_x=string(x)
qui gen string_y=string(y)
qui egen coordinate=concat(string_x string_y),punct(" ")

qui gen log_predicted_value=log(predicted_value)
//Label each variable
//label variable R "date since 2007/9/30"
label variable num_distance_shenou "distance to shenou in km"
label variable D "1 if date>2007/09/30 0 otherwise"
label variable shenou_dummy "1 if within shenou 50kms"
label variable coordinate "string coordinate"


keep predicted_value log_predicted_value R D Dshenou shenou_dummy coordinate
regress predicted_value R D Dshenou shenou_dummy,absorb(coordinate)
regress log_predicted_value R D Dshenou shenou_dummy,absorb(coordinate)



	}
}
log close
    
