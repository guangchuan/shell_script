#!/bin/bash
# set -x
# hostname      templatename
url="http://127.0.0.1/zabbix/api_jsonrpc.php"
AUTH=`curl -s -X POST -H 'Content-Type:application/json' -d'{"jsonrpc": "2.0","method":"user.authenticate","params":{"user":"Admin","password":"password"},"auth": null,"id":0}' http://127.0.0.1/zabbix/api_jsonrpc.php | cut -d '"' -f8`

PFILE=$1
if [ $# -ne 1 ];then
        echo "引数を指定してください。"
        exit 0
fi

row=`cat ${PFILE} |wc -l`
for i in `seq 1 $row`;do
  HOSTNAME=`head -n ${i} ${PFILE}|tail -1| cut -f1`
  TNAME=`head -n ${i} ${PFILE}|tail -1| cut -f2`
  if [ -z ${HOSTNAME} ] || [ -z ${TNAME} ] ;then
    echo "not find list. exit"
    exit 0
  else
  # get hostid
  HOSTID=`mysql -uroot -pXXXXXXXX zabbix -N -B -e"select hostid from hosts where host='${HOSTNAME}';"`
  # get tmplid
  TID=`mysql -uroot -pXXXXXXXX zabbix -N -B -e"select hostid from hosts where host='${TNAME}';"`
  # host.massAdd (templates)
  echo "--- ${HOSTNAME} ${TNAME} ---"
  curl -X POST -H "Content-Type:application/json-rpc" "${url}" -d '
  {
      "jsonrpc": "2.0",
      "method": "host.massAdd",
      "params": {
      "hosts":{
          "hostid": "'${HOSTID}'"
          },
      "templates": [{
              "templateid": "'${TID}'"
           }]
      },
      "auth": "'${AUTH}'",
      "id": 0
  }'
  echo -e "\n"
  fi
done
