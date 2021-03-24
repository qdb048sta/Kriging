cd "D:\User_Data\Desktop\kriging\Shenou\data\Python_kriging_data\dataset"
global POLL="SO2 PM2.5 PM10 NO2"
foreach poll of global POLL{
	global TYPE "avg max"
	foreach type of global TYPE{
		use "`poll'_`type'_kriging_2000_2021.dta",clear
		/////////////////THIS PART IS PROCESSING RAW DATA////////////////////////
		geodist 25.1272 121.8156 y x,generate(num_distance_shenou)
		geodist 24.1618378 120.6446744 y x, generate(num_distance_taichung)
		geodist 22.6614546 120.2821877 y x, generate(num_distance_kaohsiung)
		keep if num_distance_shenou<=50 | num_distance_taichung<=50 | num_distance_kaohsiung<=50

		//eliminate outlier
		egen p1p=pctile(predicted_value),p(1)
		egen p99p=pctile(predicted_value),p(99)
		drop if predicted_value<p1p | predicted_value>p99p
		//handling date and month
		tostring(date),replace
		qui gen year=substr(date,1,4)
		qui gen R=date(date,"YMD")
		qui gen month=month(R)
		qui tostring(month),gen(str_month)
		qui gen monthly=year+"m"+str_month
		qui gen month_R=monthly(monthly,"YM")
			
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

		qui egen month_avg=mean(predicted_value), by(month_R coordinate)
		qui gen log_month_avg=log(month_avg)
		/////////////END OF PROCESSING///////////////
		duplicates drop month_R,force
		keep month_R D shenou_dummy month_avg log_month_avg coordinate
		
		qui tw (lpoly month_avg month_R if shenou_dummy==1 & D==0)(lpoly month_avg month_R if shenou_dummy==1 & D==1)(lpoly month_avg month_R if shenou_dummy==0 & D==0,lpattern(dash_dot))(lpoly month_avg month_R if shenou_dummy==0 & D==1,lpattern(dash_dot)),legend(lab (1 "S==1 D==0") lab(2 "S==1 D==1") lab(3 "S==0 D==0") lab(4 "S==0 D==1")) title("`poll'_`type'_month_avg S shenou dummy D date dummy") xlabel(480 "2000m1"  528 "2004m1"  576 "2008m1"  624 "2012m1"   672 "2016m1" 720 "2020m1")
		graph export "D:\\User_Data\\Desktop\\kriging\\Shenou\\result\\`poll'_`type'_month_avg_shenou_2000_2021.png", as(png) name("Graph") quality(100) 
		qui tw(lpoly log_month_avg month_R if shenou_dummy==1 & D==0) (lpoly log_month_avg month_R if shenou_dummy==1 & D==1)(lpoly log_month_avg month_R if shenou_dummy==0 & D==0, lpattern(dash_dot)) (lpoly log_month_avg month_R if shenou_dummy==0 & D==1,lpattern(dash_dot)),legend(lab (1 "S==1 D==0") lab(2 "S==1 D==1") lab(3 "S==0 D==0") lab(4 "S==0 D==1")) title("`poll'_`type'_log_month_avg S shenou dummy D date dummy")xlabel(480 "2000m1"  528 "2004m1"  576 "2008m1"  624 "2012m1"   672 "2016m1" 720 "2020m1")
		graph export "D:\\User_Data\\Desktop\\kriging\\Shenou\\result\\`poll'_`type'_log_month_avg_shenou_2000_2021.png", as(png) name("Graph") quality(100) 
		clear
		}
}		
