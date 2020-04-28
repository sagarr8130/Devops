#!/bin/bash
end_year=`date '+%Y:%m:%d:%T' | cut -d: -f1`
end_month=`date '+%Y:%m:%d:%T' | cut -d: -f2`
end_day=`date '+%Y:%m:%d:%T' | cut -d: -f3`
end_hour=`date '+%Y:%m:%d:%T' | cut -d: -f4`
start_year=`date -d '8 hours ago' '+%Y:%m:%d:%T'| cut -d: -f1`
start_month=`date -d '8 hours ago' '+%Y:%m:%d:%T'| cut -d: -f2`
start_day=`date -d '8 hours ago' '+%Y:%m:%d:%T'| cut -d: -f3`
start_hour=`date -d '8 hours ago' '+%Y:%m:%d:%T'| cut -d: -f4`
time=`date +%Y%m%d%H%M`
echo "================================================================"
echo "Report Start Time:$start_year:$start_month:$start_day:$start_hour:00"
echo "================================================================"
echo "Report End Time:$end_year:$end_month:$end_day:$end_hour:00"
echo "================================================================"
list=(
"DIT.AEM.ProspectURLs_VIP"
"DIT.AIP.AutomaticInvestingCenter_VIP"
"DIT.APNS.sa.XXX.com_VIP"
"DIT.AUTH_APP.HeartBeat_VIP"
"DIT.BANK.AccountStatements_VIP"
"DIT.BRKG.PreviewOrder_VIP"
"DIT.IPO.offerings_VIP"
"DIT.TSP_MM.movemoney_VIP"
"DIT.TSP_RIS.irarollover_VIP"
"DIT.TSP_RIS.retirementcenter_VIP"
"DIT.TSP_SP.ExerciseStockPlan_VIP"
)


echo "<html>" >> $ET_INSTANCE_ROOT/var/html_reports/scorecard_$time.html
echo "<head>" >> $ET_INSTANCE_ROOT/var/html_reports/scorecard_$time.html
echo "<title>DIT Availablility Report</title>" >> $ET_INSTANCE_ROOT/var/html_reports/scorecard_$time.html
echo "</head>" >> $ET_INSTANCE_ROOT/var/html_reports/scorecard_$time.html
echo "<body>" >> $ET_INSTANCE_ROOT/var/html_reports/scorecard_$time.html
echo "<h1>DIT Site Availability</h1>" >> $ET_INSTANCE_ROOT/var/html_reports/scorecard_$time.html
echo "<table border="1" width="60%">" >> $ET_INSTANCE_ROOT/var/html_reports/scorecard_$time.html
echo "<tr>" >> $ET_INSTANCE_ROOT/var/html_reports/scorecard_$time.html
echo "<th> Site_name</th>" >> $ET_INSTANCE_ROOT/var/html_reports/scorecard_$time.html
echo "<th> Availablility</th>" >> $ET_INSTANCE_ROOT/var/html_reports/scorecard_$time.html
echo "</tr>" >> $ET_INSTANCE_ROOT/var/html_reports/scorecard_$time.html
echo "<tbody>" >> $ET_INSTANCE_ROOT/var/html_reports/scorecard_$time.html


for VIP_TEST in ${list[@]} ; do
AVAIL=`curl -s "http://ditdashboard.XXX.com/cgi-bin/LongTermGraphs.cgi?tests=$VIP_TEST&startyear=$start_year&startmonth=$start_month&startmday=$start_day&starthour=$start_hour&endyear=$end_year&endmonth=$end_month&endmday=$end_day&endhour=$end_hour&xdatainc=Hourly&xstub=1%20Hour%20%28Hourly%29&Submit=Create" | grep REL | cut -f2 -d' '|cut -d= -f2`


echo "<tr><td>$VIP_TEST</td><td>$AVAIL</td></tr>" >> $ET_INSTANCE_ROOT/var/html_reports/scorecard_$time.html

done


echo "</tbody>" >> $ET_INSTANCE_ROOT/var/html_reports/scorecard_$time.html
echo "</table>" >> $ET_INSTANCE_ROOT/var/html_reports/scorecard_$time.html
echo "</body>" >> $ET_INSTANCE_ROOT/var/html_reports/scorecard_$time.html
echo "</html>" >> $ET_INSTANCE_ROOT/var/html_reports/scorecard_$time.html
echo "please access http://adm2m7.XXX.com:9999/html_reports/scorecard_$time.html"
