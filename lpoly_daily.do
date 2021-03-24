cd "D:\User_Data\Desktop\kan-2\kriging"
global POLL="SO2 PM2.5 PM10 NO2"
foreach poll of global POLL{
	global TYPE "avg max"
	foreach type of global TYPE{

		use "`poll'_`type'_with_date_combined.dta"
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
		qui gen R=date(date,"YMD")

			
		//generate dummy variables
		qui gen D=1 if R>date("20070930","YMD")
		qui replace D=0 if missing(D)
		qui gen shenou_dummy=1 if num_distance_shenou<=50
		qui replace shenou_dummy=0 if missing(shenou_dummy)
		qui gen Dshenou = D*shenou_dummy
		//get coordinate for absorb
		qui gen string_x=string(x)
		qui gen string_y=string(y)
		qui egen coordinate=concat(string_x string_y),punct(" ")

		//get log_predicted_value
		qui gen log_predicted_value=log(predicted_value)

		//////////////////////END OF PROCESSING///////////////
		keep R D shenou_dummy predicted_value log_predicted_value
		save "`poll'_`type'_daily_unique_graphing.dta",replace
		qui tw (lpoly predicted_value R if shenou_dummy==1 & D==0)(lpoly predicted_value R if shenou_dummy==1 & D==1)(lpoly predicted_value R if shenou_dummy==0 & D==0,lpattern(dash_dot))(lpoly predicted_value R if shenou_dummy==0 & D==1,lpattern(dash_dot)), ///
		legend(lab (1 "S==1 D==0") lab(2 "S==1 D==1") lab(3 "S==0 D==0") lab(4 "S==0 D==1")) title("`poll'_`type'_daily S shenou dummy D date dummy")
		graph export "D:\\User_Data\\Desktop\\kan-2\\`poll'_`type'_daily_shenou.jpg", as(jpg) name("Graph") quality(100)
		qui tw(lpoly log_month_avg R if shenou_dummy==1 & D==0) (lpoly log_month_avg R if shenou_dummy==1 & D==1)(lpoly log_month_avg R if shenou_dummy==0 & D==0, lpattern(dash_dot)) (lpoly log_month_avg R if shenou_dummy==0 & D==1,lpattern(dash_dot)),legend(lab (1 "S==1 D==0") lab(2 "S==1 D==1") lab(3 "S==0 D==0") lab(4 "S==0 D==1")) title("`poll'_`type'_log_daily S shenou dummy D date dummy")
		graph export "D:\\User_Data\\Desktop\\kan-2\\`poll'_`type'_daily_shenou.jpg", as(jpg) name("Graph") quality(100)
		clear
		}
}		
