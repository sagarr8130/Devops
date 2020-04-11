#!/bin/sh
REFRESH_TOKEN="e1f09f2e3b8cc6316377c1400f108d7962be817b"
TOKEN_ENDPOINT="us-4.rightscale.com"
#ACCOUNT=106388
PROJECT=$1
case $PROJECT in
   cfn)
       ACCOUNT=106388
        ;;
   cust)
       ACCOUNT=108022
        ;;
esac

LOG_FILE=./IP_HostNames

retry_args="--retry=5 --timeout=60"
# ACCOUNT and REFRESH_TOKEN and TOKEN_ENDPOINT should be inputs
auth_args="--account=$ACCOUNT --refreshToken=$REFRESH_TOKEN --host=$TOKEN_ENDPOINT"
# Obtain deployments in the account
#deployment_hrefs=$(rsc $retry_args $auth_args cm15 index /api/deployments "filter[]=name==w50" --x1 ':has(.rel:val("self")).href')
rsc $retry_args $auth_args cm15 index /api/deployments "filter[]=name==$2" --xm '.name' |sed 's/\"//g' > ./target_deployments

while read line; do
echo "*****************************************************************" | tee -a ${LOG_FILE}
echo "           Deployment Name is $line" | tee -a ${LOG_FILE}
echo "*****************************************************************" | tee -a ${LOG_FILE}
        deployment_href=$(rsc $retry_args $auth_args \
        cm15 index /api/deployments "filter[]=name==$line" \
        --x1 ':has(.rel:val("self")).href')

#Get individual instances in the deployment
target_instances_href=$(rsc $retry_args $auth_args \
        cm15 servers $deployment_href \
        --xm ':has(.rel:val("current_instance")).href'| tr -d '"')

for instance_href in $target_instances_href; do
  # Obtain resource_uid from instance to be used to specify where to run RightScript
  instance_ruid=$(
    rsc $retry_args $auth_args \
    cm15 show $instance_href \
        --x1 '.resource_uid' | tr -d '"'
)
 cloud_attribute=$(echo $instance_href | cut --delimiter='/' --fields=-5)

 private_ip_address=$(
    rsc $retry_args $auth_args \
    cm15 show $instance_href \
        --x1 '.private_ip_addresses' | tr -d '"' | tr -d '[' | tr -d ']'
)
instance_name=$(echo $instance_ruid | awk -F"/" ' {print $4 }' )
echo "$instance_name   : $private_ip_address" | tee -a ${LOG_FILE}

##WRITE STOP ACTION CODE
done

#Get the server arrays in the deployment
echo "" | tee -a ${LOG_FILE}
server_array_href=$(rsc $retry_args $auth_args cm15 index $deployment_href/server_arrays  --xm ':has(.rel:val("self")).href'| tr -d '"')

for array_href in $server_array_href; do
server_array_instances=$(rsc $retry_args $auth_args cm15 current_instances $array_href --xm ':has(.rel:val("self")).href'| tr -d '"')
#echo $server_array_instances | tee -a ${LOG_FILE}
#Instances in Server Arrays
for instance_href in $server_array_instances; do
  # Obtain resource_uid from instance to be used to specify where to run RightScript
  instance_ruid=$(
    rsc $retry_args $auth_args \
    cm15 show $instance_href \
        --x1 '.resource_uid' | tr -d '"'
)
 cloud_attribute=$(echo $instance_href | cut --delimiter='/' --fields=-5)

 private_ip_address=$(
    rsc $retry_args $auth_args \
    cm15 show $instance_href \
        --x1 '.private_ip_addresses' | tr -d '"' | tr -d '[' | tr -d ']'
)
instance_name=$(echo $instance_ruid | awk -F"/" ' {print $4 }' )
echo "$instance_name   : $private_ip_address" | tee -a ${LOG_FILE}
##WRITE STOP ACTION CODE
done
done
done < ./target_deployments
