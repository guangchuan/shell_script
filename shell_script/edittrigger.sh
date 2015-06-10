#!/bin/sh
# 機能：同ディレクトリ内の *.csvファイルを読み込み、"ifHCInBroadcastPkts"の文字列で、トリガー用csvを作成
# 2014.03.04 v1.0 初版
MESSAGE="In too many Broadcast Packets"
WHERE=".last(0)}>192000"
LOG_FILE="joblog.log"

echo "'description','expression','priority','status','templatename'" > trigger_header

for i in `ls *.csv`;do
	TMPL_NAME=`echo "${i}" | sed -e "s/.csv$//"`
	cat "${i}" | grep "ifHCInBroadcastPkts" >> ${TMPL_NAME}.BROADCAST
	row=`cat ${TMPL_NAME}.BROADCAST | wc -l`

	if [ ${row} -ne 0 ];then

		echo "${i}からトリガー作成。${row}件"

		for j in `cat ${TMPL_NAME}.BROADCAST`;do
			T_NAME=`echo "${j}" | cut -d',' -f5 |sed -e "s/'//g"`
			IF_NAME=`echo "${j}" | cut -d',' -f6 |sed -e "s/'//g" -e "s/ifHCInBroadcastPkts_//"`
			KEY=`echo "${j}" | cut -d',' -f7 |sed -e "s/'//g"`
			# echo csv
			echo "'${IF_NAME} ${MESSAGE}','{${T_NAME}:${KEY}${WHERE}','4','0','${T_NAME}'" >> TRIGGER
		done

	cat trigger_header TRIGGER >> TRIGGER_${TMPL_NAME}.csv
	rm -f TRIGGER ${TMPL_NAME}.BROADCAST

	fi
done
rm -f  trigger_header *.BROADCAST
