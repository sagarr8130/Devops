Intent to Repository

This repository mainly consist of few automation task which is beneficial to reduce DevOps operational effort to support developers and team. Here is a little brief of all the projects :-


1) Rolling_Restart.sh

A complex code delivered to cloud-ops team so that they can restart wfc process in rolling manner. Script can be run from single instance where it is able to fetch private IP's from `RightScale (Cloud Management Tool)` and then take restart of dockerized wfc service in rolling manner. Code is basically developed to reduce human effort and mistake without any downtime. 


2) redis_key_count.sh

Shell Script use to compare total number of dockerized redis key count during `BLUE-GREEN` upgrade strategy.


3) Logview.sh

It is a script use to provide logview web portal to developers in QA and production environment so that developers can debug the logs without accessing any host.

2) Site Availability

A HTML tabular report which was achieved by simple shell script to check the critical application availability at the eod. This script is basically used for management purpose to showcase the application availability.
