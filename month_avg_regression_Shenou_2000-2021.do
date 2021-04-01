clear
local POLL="PM2.5 PM10 SO2 NO2"
local value="avg max"
cd "D:\User_Data\Desktop\kriging"
log using "D:\User_Data\Desktop\kriging\Shenou\result\month_reg_r_2000-2016.log",replace
set more off
set linesize 255
cap log c
foreach poll of local POLL{
    foreach v of local value{


display "---------------------Daily `v' of `poll'------------------------------"
use "D:\User_Data\Desktop\kriging\Shenou\data\R_kriging_data\dataset\\`poll'_`v'_kriging_2000_2021.dta" ,clear

//filter out only within target <=50km
geodist 25.1272 121.8156 y x,generate(num_distance_shenou)
geodist 24.1618378 120.6446744 y x, generate(num_distance_taichung)
geodist 22.6614546 120.2821877 y x, generate(num_distance_kaohsiung)
keep if num_distance_shenou<=50 | num_distance_taichung<=50 | num_distance_kaohsiung<=50



//handling date and month
tostring(date),replace
qui gen year=substr(date,1,4)
qui gen R=date(date,"YMD")
qui gen month=month(R)
qui tostring(month),gen(str_month)
qui gen monthly=year+"m"+str_month
qui gen month_R=monthly(monthly,"YM")

//eliminate outlier and restrict date
if "`poll'"=="PM2.5"{
	gen R2006=date("20060101","YMD")
	gen R2011=date("20110930","YMD")
	gen R2003=date("20030930","YMD")
	drop if R<R2006
	drop if R>2011
	drop if R<2003
	
	drop R2006
	drop R2011
	drop R2003
}
if "`poll'"=="PM10"{
	gen R2006=date("20000101","YMD")
	gen R2011=date("20110930","YMD")
	gen R2003=date("20030930","YMD")
	drop if R<R2006
	drop if R>2011
	drop if R<2003
	
	drop R2006
	drop R2011
	drop R2003
}
if "`poll'"=="SO2"{
	gen R2006=date("20000101","YMD")
	gen R2011=date("20110930","YMD")
	gen R2003=date("20030930","YMD")
	drop if R<R2006
	drop if R>2011
	drop if R<2003
	
	drop R2006
	drop R2011
	drop R2003
}
if "`poll'"=="NO2"{
	gen R2006=date("20000101","YMD")
	gen R2011=date("20110930","YMD")
	gen R2003=date("20030930","YMD")
	drop if R<R2006
	drop if R>2011
	drop if R<2003
	
	drop R2006
	drop R2011
	drop R2003
}


egen p1p=pctile(var1pred),p(1)
egen p99p=pctile(var1pred),p(99)
drop if var1pred<p1p | var1pred>p99p
drop p1p p99p

	//generate dummy variables
qui gen D=1 if month_R>monthly("2007m9","YM")
qui replace D=0 if missing(D)
qui gen shenou_dummy=1 if num_distance_shenou<=50
qui replace shenou_dummy=0 if missing(shenou_dummy)
qui gen Dshenou = D*shenou_dummy
//get coordinate for absorb
qui gen string_x=string(x)
qui gen string_y=string(y)
qui egen coordinate=concat(string_x string_y),punct(" ")

//get monthly average

qui egen month_avg=mean(var1pred), by(month_R coordinate)
qui gen log_month_avg=log(month_avg)
//qui gen log_var1pred=log(var1pred)
//Label each variable
//label variable R "date since 2007/9/30"
label variable num_distance_shenou "distance to shenou in km"
label variable D "1 if date>2007/09/30 0 otherwise"
label variable shenou_dummy "1 if within shenou 50kms"
label variable coordinate "string coordinate"


keep month_avg log_month_avg month_R D Dshenou shenou_dummy coordinate
duplicates drop month_R coordinate, force  
regress month_avg month_R D Dshenou shenou_dummy,absorb(coordinate)
regress log_month_avg month_R D Dshenou shenou_dummy,absorb(coordinate)



	}
}
log close
    
