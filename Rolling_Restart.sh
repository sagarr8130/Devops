#!/bin/bash

###############################################################################
#Script Name    : rolling.sh
#Description    : Rolling Restart of WFM Cluster
#Author         : Sagar Saxena
#Email          : cloudautomation@XXX.com
################################################################################


fun1() { sudo /usr/local/XXX/wfc/bin/wfc kill; sleep 10; sudo /usr/local/XXX/wfc/bin/wfc start; }
fun2() { sudo /usr/local/XXX/wfc/bin/wfc status; }

REFRESH_TOKEN="TODO"
TOKEN_ENDPOINT="TODO"
ACCOUNT=TODO
retry_args="--retry=5 --timeout=60"
auth_args="--account=$ACCOUNT --refreshToken=$REFRESH_TOKEN --host=$TOKEN_ENDPOINT"

###Fetching Private IPs Of Desired Deployment 

while read i; do
rsc $retry_args $auth_args cm15 index /api/deployments "filter[]=name==$i" --xm '.name' |sed 's/\"//g' | grep -i ^WFM >>./target_deployments
done <./deployments


while read line;do
 file=$(echo $line | awk '{print $1}' | cut -c -5)
 deployment_href=$(rsc $retry_args $auth_args cm15 index /api/deployments "filter[]=name==$line" --xm ':has(.rel:val("self")).href'| sed 's/\"//g')
 instance_href=$(rsc $retry_args $auth_args cm15 servers $deployment_href --xm ':has(.rel:val("current_instance")).href'| tr -d '"')
 instance_name=$(rsc $retry_args $auth_args cm15 show $instance_href --xm '.resource_uid' | tr -d '"' | awk -F"/" ' {print $4 }')
 private_ip_address=$(rsc $retry_args $auth_args cm15 show $instance_href --xm '.private_ip_addresses' | tr -d '"' | tr -d '[' | tr -d ']')
 echo -e "\n############## $file PRIVATE IP \n"
 echo "$instance_name   : $private_ip_address" | tee -a $file.txt

 server_array_href=$(rsc $retry_args $auth_args cm15 index $deployment_href/server_arrays  --xm ':has(.rel:val("self")).href'| tr -d '"')
 for array_href in $server_array_href; do
 server_array_instances=$(rsc $retry_args $auth_args cm15 current_instances $array_href --xm ':has(.rel:val("self")).href'| tr -d '"')
 for instance_href in $server_array_instances; do
 instance_name=$(rsc $retry_args $auth_args cm15 show $instance_href --x1 '.resource_uid' | tr -d '"'| awk -F"/" ' {print $4 }')
 private_ip_address=$(rsc $retry_args $auth_args cm15 show $instance_href --x1 '.private_ip_addresses' | tr -d '"' | tr -d '[' | tr -d ']')
 echo "$instance_name   : $private_ip_address" |tee -a $file.txt
 done
 done

done<./target_deployments
sed -i '/fnt/d' WFM*.txt



###WFC Part A Restart Action Code

for node in `ls | grep -i WFM`;do
cmd=$(ssh -q -o StrictHostKeyChecking=no cloudautomation@`cat $node | grep -i ilb | awk '{print $3}'` "docker exec nginx-ilb cat /var/lib/nginx/state/wfm_backend_nginx.state" | wc -l)
 case $cmd in
        2*) ssh -q -o StrictHostKeyChecking=no cloudautomation@`cat $node | grep -i ilb | awk '{print $3}'` "docker exec nginx-ilb sed -i '1s/^/#/' /var/lib/nginx/state/wfm_backend_nginx.state"
			ssh -q -o StrictHostKeyChecking=no cloudautomation@`cat $node | grep -i ilb | awk '{print $3}'` "docker exec nginx-ilb sed -i '1s/^/#/' /var/lib/nginx/state/wfm_backend_api.state"
			ssh -q -o StrictHostKeyChecking=no cloudautomation@`cat $node | grep -i ilb | awk '{print $3}'` "docker exec nginx-ilb nginx -s reload"
			i=$(ssh -q -o StrictHostKeyChecking=no cloudautomation@`cat $node | grep -i ilb | awk '{print $3}'` "docker exec nginx-ilb cat /var/lib/nginx/state/wfm_backend_nginx.state| grep -i ^#| cut -d "." -f 1 | cut -d ' ' -f 2")
			j=$(ssh -q -o StrictHostKeyChecking=no cloudautomation@`cat $node | grep -i ilb | awk '{print $3}'` "docker exec nginx-ilb cat /var/lib/nginx/state/wfm_backend_api.state| grep -i ^#| cut -d "." -f 1 | cut -d ' ' -f 2")
			ssh -q -o StrictHostKeyChecking=no cloudautomation@`grep -i $i $node  | awk '{print $3}'` "$(typeset -f fun1); fun1"
			sed -i "/`grep -i $i $node`/s/^/#/g" $node
			ssh -q -o StrictHostKeyChecking=no cloudautomation@`grep -i bgp $node  | head -1 |awk ' {print $3}'` "$(typeset -f fun1); fun1"
			sed -i "/`grep -i bgp $node  | head -1`/s/^/#/g" $node
			ssh -q -o StrictHostKeyChecking=no cloudautomation@`grep -i $j $node  | awk '{print $3}'` "$(typeset -f fun1); fun1"
			sed -i "/`grep -i $j $node`/s/^/#/g" $node
		;;
        5*) ssh -q -o StrictHostKeyChecking=no cloudautomation@`cat $node | grep -i ilb | awk '{print $3}'` "docker exec nginx-ilb sed -i '1,2s/^/#/' /var/lib/nginx/state/wfm_backend_nginx.state"
			 ssh -q -o StrictHostKeyChecking=no cloudautomation@`cat $node | grep -i ilb | awk '{print $3}'` "docker exec nginx-ilb sed -i '1,2s/^/#/' /var/lib/nginx/state/wfm_backend_api.state"
			 ssh -q -o StrictHostKeyChecking=no cloudautomation@`cat $node | grep -i ilb | awk '{print $3}'` "docker exec nginx-ilb nginx -s reload"
			 for element in $(ssh -q -o StrictHostKeyChecking=no cloudautomation@`cat $node | grep -i ilb | awk '{print $3}'` "docker exec nginx-ilb cat /var/lib/nginx/state/wfm_backend_nginx.state| grep -i ^#| cut -d "." -f 1 | cut -d ' ' -f 2");do
             ssh -q -o StrictHostKeyChecking=no cloudautomation@`grep -i $element $node| awk '{print $3}'` "$(typeset -f fun1); fun1"
             sed -i "/`grep -i $element $node`/s/^/#/g" $node
			 done
			 for element in `grep -i bgp $node  | head -2 |awk ' {print $3}'`;do
             ssh -q -o StrictHostKeyChecking=no cloudautomation@$element "$(typeset -f fun1); fun1"
             sed -i "/`grep -i $element $node`/s/^/#/g" $node
			 done
			 for element in $(ssh -q -o StrictHostKeyChecking=no cloudautomation@`cat $node | grep -i ilb | awk '{print $3}'` "docker exec nginx-ilb cat /var/lib/nginx/state/wfm_backend_api.state| grep -i ^#| cut -d "." -f 1 | cut -d ' ' -f 2");do
			 ssh -q -o StrictHostKeyChecking=no cloudautomation@`grep -i $element $node| awk '{print $3}'` "$(typeset -f fun1); fun1"
			 sed -i "/`grep -i $element $node`/s/^/#/g" $node
			 done
		;;
 esac
done


###WFC Part A Status Check & WFC Part B Restart Action Code

COUNTER=0
 while true
 do
        COUNTER=$((COUNTER+1))
        sleep 15
        cat WFM*.txt | grep -i ^# >/dev/null
        OUT=$?
        if [ $OUT -eq 1 ];then
        break
        else
         for i in `ls | grep -i WFM | grep -i txt`
         do
		   cat /dev/null > /tmp/status.log
           for IP in `cat $i  | grep -i ^# | awk '{print $3}'`
           do
             ssh -q -o StrictHostKeyChecking=no cloudautomation@$IP "$(typeset -f fun2); fun2" | grep -i 'WFC Server has been started in Online Mode'
             OUT=$?
              if [ $OUT -eq 1 ];then
              echo $OUT > /tmp/status.log
              fi
           done

              if [[ `ls -l /tmp/status.log | awk '{print $5}'` -eq 0 ]] ; then
                ssh -q -o StrictHostKeyChecking=no cloudautomation@`cat $i | grep -i ilb | awk '{print $3}'` "docker exec nginx-ilb sed -i '1,$ s/^/#/' /var/lib/nginx/state/wfm_backend_nginx.state /var/lib/nginx/state/wfm_backend_api.state"
                ssh -q -o StrictHostKeyChecking=no cloudautomation@`cat $i | grep -i ilb | awk '{print $3}'` "docker exec nginx-ilb sed -i 's/^##//g' /var/lib/nginx/state/wfm_backend_nginx.state /var/lib/nginx/state/wfm_backend_api.state"
                ssh -q -o StrictHostKeyChecking=no cloudautomation@`cat $i | grep -i ilb | awk '{print $3}'` "docker exec nginx-ilb nginx -s reload"

                  for j in `cat $i  | egrep -iv '^#|ilb' | awk '{print $3}'`;do
                    ssh -q -o StrictHostKeyChecking=no cloudautomation@$j "$(typeset -f fun1); fun1"
                  done

                sed -i '2,$ s/^/#/' $i
                sed -i 's/^##//g' $i
                mv $i `echo $i | cut -d . -f1`

              fi

              if [ $COUNTER -eq 180 ]; then
              echo -e "Check WFC LOGS"
              break
              fi
        done
       fi
 done



for i in `ls | grep -i WFM`;do
mv $i $i.txt
done


###WFC Part B Status Check Code

COUNTER=0
 while true
 do
        COUNTER=$((COUNTER+1))
        sleep 15
        cat WFM*.txt | grep -i ^# >/dev/null
        OUT=$?
        if [ $OUT -eq 1 ];then
        break
        else
         for i in `ls | grep -i WFM | grep -i txt`
         do
           cat /dev/null > /tmp/status.log
		   for IP in `cat $i  | grep -i ^# | awk '{print $3}'`
           do
            ssh -q -o StrictHostKeyChecking=no cloudautomation@$IP "$(typeset -f fun2); fun2" | grep -i 'WFC Server has been started in Online Mode'
            OUT=$?
             if [ $OUT -eq 1 ];then
              echo $OUT > /tmp/status.log
             fi
           done

          if [[ `ls -l /tmp/status.log | awk '{print $5}'` -eq 0 ]] ; then
           ssh -q -o StrictHostKeyChecking=no cloudautomation@`cat $i | grep -i ilb | awk '{print $3}'` "docker exec nginx-ilb sed -i 's/^#//g' /var/lib/nginx/state/wfm_backend_nginx.state /var/lib/nginx/state/wfm_backend_api.state"
           ssh -q -o StrictHostKeyChecking=no cloudautomation@`cat $i | grep -i ilb | awk '{print $3}'` "docker exec nginx-ilb nginx -s reload"
           sed -i 's/#//g' $i
          fi

          if [ $COUNTER -eq 180 ]; then
           echo -e "Check WFC LOGS"
           break
          fi

        done
        fi
 done




###SCRIPT ENDED
