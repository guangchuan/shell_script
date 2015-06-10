#!/bin/bash
# hostgroup.massadd
# ホストグループにホストを登録する。
url="http://127.0.0.1/zabbix/api_jsonrpc.php"
AUTH=`curl -s -X POST -H 'Content-Type:application/json' -d'{"jsonrpc": "2.0","method":"user.authenticate","params":{"user":"Admin","password":"password"},"auth": null,"id":0}' ${url} | cut -d '"' -f8`

REMOVE_LIST=$1
if [ $# -ne 1 ];then
        echo "引数を指定してください。"
        exit 0
fi

row=`cat ${REMOVE_LIST} |wc -l`
for i in `seq 1 $row`;do
 GROUPNAME=`head -n ${i} ${REMOVE_LIST}|tail -1| cut -f1`
 HOSTNAME=`head -n ${i} ${REMOVE_LIST}|tail -1| cut -f2`
 if [ -z ${GROUPNAME} ] || [ -z ${HOSTNAME} ];then
   echo "not find list. exit"
   exit 0
 else
   # get groupid
   GROUPID=`mysql -uroot -pXXXXXXXX zabbix -N -B -e"select groupid from groups where name = '${GROUPNAME}';"`
   # get hostid
   HOSTID=`mysql -uroot -pXXXXXXXX zabbix -N -B -e"select hostid from hosts where host = '${HOSTNAME}';"`
   # hostgroup.massadd
   echo "--- hostgroup.massadd: group:[${GROUPNAME}] host:[${HOSTNAME}] ---"
   curl -X POST -H "Content-Type:application/json-rpc" "${url}" -d '
   {
       "jsonrpc": "2.0",
       "method": "hostgroup.massadd",
       "params": {
           "groups": [
               {
                   "groupid": "'${GROUPID}'"
               }
           ],
           "hosts": [
               {
                   "hostid": "'${HOSTID}'"
               }
           ]
       },
       "auth": "'${AUTH}'",
       "id": 0
   }'
   echo -e "\n"
   fi
done
