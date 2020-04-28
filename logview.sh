#!/bin/bash

cp /dev/null /XXX/home/XXX/logview.txt;
cp /dev/null /XXX/home/XXX/error.log;



for NODE in `grep -i sit /XXX/etc/deployments | egrep -v 'PP|N|^#|D|L|sit4w88m7|sit5w86m7|sit147w80m7|sit269w80m7|sit69w86m7|sit6w80m7|sit15w82m7|sit4w88m7' |cut -d : -f 5 | grep -i "^sit[1-9]"| sort | uniq`;do

OS=$(etcmd -s kmssh root@$NODE facter operatingsystemmajrelease)

FW=$(etisedna -m $NODE| cut -d : -f 2)



if [ `curl -sL -w "%{http_code}\\n" "http://$NODE.XXX.com:2424/" -o /dev/null` = 000 ] ; then

        if [ $OS == 5 ] && [ $FW == 1 ]; then
        echo "adm:etadm:web:logview:$NODE:logviewer:1:syseng,admins,occsys:edna" >> /XXX/home/XXX/logview.txt
        elif [ $OS == 6 ] && [ $FW == 1 ]; then
        echo "adm:etadm:web:logview:$NODE:logviewer:1:syseng,admins,occsys:edna-centos6" >> /XXX/home/XXX/logview.txt
        elif [ $OS == 7 ] && [ $FW == 1 ] ; then
        echo "adm:etadm:web:logview:$NODE:logviewer:1:syseng,admins,occsys:edna-centos7" >> /XXX/home/XXX/logview.txt
        else
        echo "adm:etadm:web:logview:$NODE:generic_content:1:syseng,admins,occsys" >> /XXX/home/XXX/logview.txt

        fi

fi


done


read -p "Press Enter to continue after verifying logview.txt"


############Committing Changes#############################


svn commit --username XXX --password XXX --non-interactive --trust-server-cert

cat /XXX/home/XXX/logview.txt >> /XXX/home/XXX/etmeta/deployments


read -p "Press Enter to continue and verify logview.txt"
cd /XXX/home/XXX/etmeta
svn commit deployments -m "Adding missing logview deployments" --username <USERNAME> --password <LDAPID> --non-interactive --trust-server-cert



############Installation Begins from here##################


for NODE in `cat /XXX/home/XXX/logview.txt | cut -d : -f 5`;do

FW=$(etisedna -m $NODE| cut -d : -f 2)

CODE=$(curl -sL -w "%{http_code}\\n" "http://$NODE.XXX.com:2424/" -o /dev/null)

        if [ $FW == 1 ] ; then
        etcmd -s kmssh root@$NODE /usr/bin/edna -d adm-etadm-web-logview -c stop
        etcmd -s kmssh root@$NODE /usr/bin/edna -d adm-etadm-web-logview -c install -f
        etcmd -s kmssh root@$NODE /usr/bin/edna -d adm-etadm-web-logview -c start

        else
        etupdate -fvn $NODE
        etrcmd -d -n $NODE -e adm -a etadm -s web -i logview etcmd etrpmadd
        etrcmd -d -n $NODE -e adm -a etadm -s web -i logview etcmd etserver stop
        etrcmd -d -n $NODE -e adm -a etadm -s web -i logview etcmd etserver -f install
        etrcmd -d -n $NODE -e adm -a etadm -s web -i logview etcmd etserver start

        fi

        if [ $CODE != 200 ] || [ $CODE != 401 ] ; then
        echo "$NODE  is throwing $CODE http response code, Please check it manually." >> /XXX/home/XXX/error.log
        fi

done
