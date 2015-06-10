#!/bin/bash
# host.massremove
# ホストからからテンプレートを除外する。
url="http://127.0.0.1/zabbix/api_jsonrpc.php"
AUTH=`curl -s -X POST -H 'Content-Type:application/json' -d'{"jsonrpc": "2.0","method":"user.authenticate","params":{"user":"Admin","password":"password"},"auth": null,"id":0}' ${url} | cut -d '"' -f8`

REMOVE_LIST=host.massremove.txt
CHECK_HOSTNAME=$(cat $REMOVE_LIST | awk '{print $1}'| sed -e "s/^/'/g" -e "s/$/'/g")
CHECK_HOSTNAME2=$(echo $CHECK_HOSTNAME | sed "s/ /,/g")

FUNC_CONTROL()
{
echo "--- [Enter]:next. [CTRL+C]:stop---"
read Wait
}

FUNC_SHOW_TEMP()
{
mysql -uroot -pXXXXXXXX zabbix -e "
select h1.host as host,h2.host as templatename
from hosts_templates ht
inner join hosts h1 on h1.hostid = ht.hostid
inner join hosts h2 on h2.hostid = ht.templateid
where h1.host in (${CHECK_HOSTNAME2})
order by h1.host;
"
}

echo "=== get before TEMPLATE ==="
FUNC_SHOW_TEMP > host.massremove_before.txt
ls -l host.massremove_before.txt
FUNC_CONTROL

echo "=== start host.massremove ==="
row=`cat ${REMOVE_LIST} |wc -l`
for i in `seq 1 $row`;do
 HOSTNAME=`head -n ${i} ${REMOVE_LIST}|tail -1| cut -f1`
 TEMPNAME=`head -n ${i} ${REMOVE_LIST}|tail -1| cut -f2`

 # get groupid
 HOSTID=`mysql -uroot -pXXXXXXXX zabbix -N -B -e"select hostid from hosts where host = '${HOSTNAME}';"`
 # get hostid
 TEMPID=`mysql -uroot -pXXXXXXXX zabbix -N -B -e"
 select distinct ht.templateid from hosts_templates ht
 inner join hosts h on h.hostid = ht.templateid where h.host = '${TEMPNAME}';"`

 # hostgroup.massremove
echo "--- hostgroup.massremove: group:[${GROUPNAME}] host:[${HOSTNAME}] ---"
curl -X POST -H "Content-Type:application/json-rpc" "${url}" -d '
{
    "jsonrpc": "2.0",
    "method": "host.massremove",
    "params": {
        "hostids": [
            "'${HOSTID}'"
        ],
        "templateids_clear": [
            "'${TEMPID}'"
        ]
    },
    "auth": "'${AUTH}'",
    "id": 0
}'

echo -e "\n"
done

echo "=== end host.massremove ==="

echo -e "\n=== get after TEMPLATE ==="
FUNC_SHOW_TEMP > host.massremove_after.txt
ls -l host.massremove_after.txt
FUNC_CONTROL

echo "=== diff hostmassremove_before.txt hostmassremove_after.txt ==="
diff host.massremove_before.txt host.massremove_after.txt
