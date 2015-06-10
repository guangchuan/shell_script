#!/bin/bash
# hostgroup.massremove
# ホストグループからホストを除外する。
url="http://127.0.0.1/zabbix/api_jsonrpc.php"
AUTH=`curl -s -X POST -H 'Content-Type:application/json' -d'{"jsonrpc": "2.0","method":"user.authenticate","params":{"user":"Admin","password":"password"},"auth": null,"id":0}' ${url} | cut -d '"' -f8`

REMOVE_LIST=hostgroup.massremove.txt
CHECK_HOSTNAME=$(cat $REMOVE_LIST | awk '{print $2}'| sed -e "s/^/'/g" -e "s/$/'/g")
CHECK_HOSTNAME2=$(echo $CHECK_HOSTNAME | sed "s/ /,/g")

FUNC_CONTROL()
{
echo "--- [Enter]:next. [CTRL+C]:stop---"
read Wait
}

FUNC_SHOW_GROUP(){
mysql -uroot -pXXXXXXXX zabbix -e "
select 
   h1.host as host,gr.name as groupname
from hosts_groups hg
inner join hosts h1 on hg.hostid = h1.hostid
inner join groups gr on hg.groupid = gr.groupid
where h1.host in (${CHECK_HOSTNAME2})
order by h1.host;
"
}

echo "=== get before HOSTGROUP ==="
FUNC_SHOW_GROUP > hostgroup.massremove_before.txt
ls -l hostgroup.massremove_before.txt
FUNC_CONTROL

echo "=== start hostgroup.massremove ==="
row=`cat ${REMOVE_LIST} |wc -l`
for i in `seq 1 $row`;do
 GROUPNAME=`head -n ${i} ${REMOVE_LIST}|tail -1| cut -f1`
 HOSTNAME=`head -n ${i} ${REMOVE_LIST}|tail -1| cut -f2`

 # get groupid
 GROUPID=`mysql -uroot -pXXXXXXXX zabbix -N -B -e"select groupid from groups where name = '${GROUPNAME}';"`
 # get hostid
 HOSTID=`mysql -uroot -pXXXXXXXX zabbix -N -B -e"select hostid from hosts where host = '${HOSTNAME}';"`

 # hostgroup.massremove
echo "--- hostgroup.massremove: group:[${GROUPNAME}] host:[${HOSTNAME}] ---"
curl -X POST -H "Content-Type:application/json-rpc" "${url}" -d '
{
    "jsonrpc": "2.0",
    "method": "hostgroup.massremove",
    "params": {
        "groupids": [
            "'${GROUPID}'"
        ],
        "hostids": [
            "'${HOSTID}'"
        ]
    },
    "auth": "'${AUTH}'",
    "id": 0
}'

echo -e "\n"
done

echo "=== end hostgroup.massremove ==="

echo -e "\n=== get after HOSTGROUP ==="
FUNC_SHOW_GROUP > hostgroup.massremove_after.txt
ls -l hostgroup.massremove_after.txt
FUNC_CONTROL

echo "=== diff hostgroup.massremove_before.txt hostgroup.massremove_after.txt ==="
diff hostgroup.massremove_before.txt hostgroup.massremove_after.txt
