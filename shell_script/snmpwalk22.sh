#!/bin/sh
: <<'#COMMENT'
##############################################
初版 2013.11.21 v1.00
修正 2013.12.09 v1.01 修正内容：1.Cisco892J追加
修正 2013.12.24 v1.02 修正内容：func_CSV()追加、"vl"が含まれるアイテム削除（VLAN削除）
修正 2013.12.27 v1.03 修正内容：ifHCOutBroadcastPktsを削除、Inのみ残す
修正 2013.12.27 v1.04 修正内容：なし
修正 2013.12.27 v1.05 修正内容：テンプレート別CSV出力。モデルにVIPRION2400を追加
修正 2014.01.09 v1.06 修正内容：IFエラーカウンタとブロードキャストの保存時の計算を修正（0:なし→2:差分）
修正 2014.01.17 v1.07 修正内容：モデルASA5505,Nexus5596,PA-4050,PA-5020,BIG-IP3900追加。CPU,MEMでOIDの末尾が*の時の不具合修 正
修正 2014.02.07 v1.08 修正内容：CPU使用率 5秒を取っている問題修正（5秒は取得しない）NOSのOID指定ミス対応（ASR1002のCPU 2件）（pfwcdn01のOID修正）
修正 2014.02.12 v1.09 修正内容：ifType問題修正
修正 2014.02.18 v1.10 修正内容：func_SETOID()作成、func_CSV()にCSVTYPE追加、およびそれに伴う修正。各funkの見直し
修正 2014.03.03 v1.20 修正内容：func_GETTMPL()作成、通信量とエラーカウンタをifNameからオンボードのI/Fか拡張I/Fかを判断し、テンプレートを分ける。
修正 2014.03.04 v1.21 修正内容：BIG-IPのSNATの種類によって、PORTのOIDが異なる対応。F5のトラフィック量取得OID修正(新OS対応"sysIfxStatHcInOctets" "sysIfxStatHcOutOctets")
修正 2014.03.13 v1.22 修正内容：Nexus5596とVIPRION2400の一部OID修正
修正 2014.04.23 v1.23 修正内容：保存日数を90から92に修正
修正 2014.04.28 v1.24 修正内容：セッション数の所属テンプレートを見直し（機器固有→機器共通テンプレート、可変的なもの→用途別テンプレート）
修正 2014.11.11 v1.25 修正内容：BIBG-IPのCPU温度のOIDを変更（OS 11.4.1対応の為）、モデルC4500X-32、モデルC4500X-16を追加
修正 2015.01.21 v1.26 修正内容：PA-500の温度取得OIDを変更。これに伴いPA-500を他のPA系機器設定と分離
修正 2015.01.21 v1.26 修正内容：新規モデル"T3048-LY2","BigTapController"に対応
修正 2015.05.25 v1.27 修正内容：新規モデル"Nexus7004","PA-2020"に対応
修正 2015.05.25 v1.27 修正内容：KMS用にASR1002のCPU使用率、BIG-IP1600のCPU温度のOIDを旧ファーム用に修正
修正 2015.05.25 v1.27 修正内容：KMS用に"Nexus7009"に対応
##############################################

■引数：なし、参照ファイル２個
  参照ファイル1：${MASTER_FILE}
  書式: タブ区切りで、以下の0~21を一行として記述
  NO    設定値                                                          意味
  0             XXX_template_Arista7050S-52         機器共通tmpl名
  1             Y                                   CPU（Y:取得、Y以外:取得しない）
  2             Y                                   メモリ（Y:取得、Y以外:取得しない）
  3             Y                                   温度（Y:取得、Y以外:取得しない）
  4             N                                   セッション数（Y:取得、Y以外:取得しない）
  5             数字                                物理インタフェース数（未使用）
  6             Y                                   通信量（IN・OUT）（Y:取得、Y以外:取得しない）
  7             Y                                   エラーカウンタ（IN・OUT）（Y:取得、Y以外:取得しない）
  8             XXX_template_pl2cor_Arista_ejo2     用途別tmpl名
  9             N                                   拡張物理IF数（未使用）
  10    数字                                論理インタフェース数（未使用）
  11    N                                   論理IF通信量（IN・OUT）（Y:取得、Y以外:取得しない）
  12    N                                   論理IFエラーカウンタ（IN・OUT）（Y:取得、Y以外:取得しない）
  13    S                                   BroadcastPkts
  14    P                                                                       ポート：P
  15    XXX_template_response               response（未使用）
  16    XXX_template_snmptrap               snmptrap（未使用）
  17    XXXejo2-pl2cor01                    ホスト名
  18    C3560X-24T                          ブランド
  19    BIG-IP1600                                                      モデル
  20    plbfrt                                                          用途シンボル名
  21    tky4                                                            拠点
  22    _01                                                                     号機
  【sample】
  XXX_template_Arista7050S-52   Y       Y       Y       －      53      Y       Y       XXX_template_pl2rac_Arista_oskc 0   －      Y       Y       －      －      XXX_template_response   XXX_template_snmptrap   XXXoskc-pl2rac01        Arista  Arista7050S-52      pl2rac  oskc

  参照ファイル2：${ITEM_NAME_FILE}
  書式: タブ区切りで、「OID   アイテム名」のように記述
  【sample】
  .1.3.6.1.2.1.25.2.3.1.6.1  memFree     3セル目以降は参照しないので、コメントなどでも.

■Output
  ・機器共通テンプレート
  ・用途別テンプレート
-------------------------------------------------
#COMMENT

func_SETOID()
{
# ifHCInOctets                                          .1.3.6.1.2.1.31.1.1.1.6
# ifHCOutOctets                                         .1.3.6.1.2.1.31.1.1.1.10
# ifInErrors                                            .1.3.6.1.2.1.2.2.1.14
# ifOutErrors                                           .1.3.6.1.2.1.2.2.1.20
# ifHCInBroadcastPkts                           .1.3.6.1.2.1.31.1.1.1.9
# ltmVirtualServStatClientCurConns  .1.3.6.1.4.1.3375.2.2.10.2.3.1.12
# ltmPoolMemberStatServerCurConns   .1.3.6.1.4.1.3375.2.2.5.4.3.1.11
# sysInterfaceStatName                          .1.3.6.1.4.1.3375.2.1.2.4.4.3.1.1
# sysInterfaceStatErrorsIn                      .1.3.6.1.4.1.3375.2.1.2.4.4.3.1.8
# sysInterfaceStatErrorsOut                     .1.3.6.1.4.1.3375.2.1.2.4.4.3.1.9
# sysIfxStatName                                        .1.3.6.1.4.1.3375.2.1.2.4.5.3.1.1               未使用、sysInterfaceStatNameにしている
# sysIfxStatHcInOctets                          .1.3.6.1.4.1.3375.2.1.2.4.5.3.1.6
# sysIfxStatHcOutOctets                         .1.3.6.1.4.1.3375.2.1.2.4.5.3.1.10
# sysIfxStatHcInBroadcastPkts           .1.3.6.1.4.1.3375.2.1.2.4.5.3.1.9

# モデル名を判断しOIDをセットする。
        case "${1}" in
                "ASA5505" )
                        IF_IN_OUT=("ifHCInOctets" "ifHCOutOctets"); IF_ERROR=("ifInErrors" "ifOutErrors"); IF_BROADCAST=("ifHCInBroadcastPkts")
                        CPU=(".1.3.6.1.4.1.9.9.109.1.1.1.1.4.1" ".1.3.6.1.4.1.9.9.109.1.1.1.1.5.1")
                        MEM=(".1.3.6.1.4.1.9.9.48.1.1.1.5.1" ".1.3.6.1.4.1.9.9.48.1.1.1.6.1")
                        TEMP=("")
                        SESSION=(".1.3.6.1.4.1.9.9.491.1.1.1.6.0")
                        PORT=("")
                        ;;
                "ASR1002" )
                        IF_IN_OUT=("ifHCInOctets" "ifHCOutOctets"); IF_ERROR=("ifInErrors" "ifOutErrors"); IF_BROADCAST=("ifHCInBroadcastPkts")
                        CPU=(".1.3.6.1.4.1.9.9.109.1.1.1.1.24.2" ".1.3.6.1.4.1.9.9.109.1.1.1.1.24.3")
                        MEM=(".1.3.6.1.4.1.9.9.48.1.1.1.5.1" ".1.3.6.1.4.1.9.9.48.1.1.1.6.1")
                        TEMP=(".1.3.6.1.4.1.9.9.91.1.1.1.1.4.1015" ".1.3.6.1.4.1.9.9.91.1.1.1.1.4.1018" ".1.3.6.1.4.1.9.9.91.1.1.1.1.4.7011" ".1.3.6.1.4.1.9.9.91.1.1.1.1.4.7012" ".1.3.6.1.4.1.9.9.91.1.1.1.1.4.9018")
                        SESSION=("")
                        PORT=("")
                        ;;
                "Arista7050S-52" | "Arista7050T-52" )
                        IF_IN_OUT=("ifHCInOctets" "ifHCOutOctets"); IF_ERROR=("ifInErrors" "ifOutErrors"); IF_BROADCAST=("ifHCInBroadcastPkts")
                        CPU=(".1.3.6.1.2.1.25.3.3.1.2.1")
                        MEM=(".1.3.6.1.2.1.25.2.3.1.5.1" ".1.3.6.1.2.1.25.2.3.1.6.1")
                        TEMP=(".1.3.6.1.2.1.99.1.1.1.4.100006001" ".1.3.6.1.2.1.99.1.1.1.4.100006002" ".1.3.6.1.2.1.99.1.1.1.4.100006003" ".1.3.6.1.2.1.99.1.1.1.4.100006004")
                        SESSION=("")
                        PORT=("")
                        ;;
                "Nexus5548_L2" | "Nexus5548_L3" | "Nexus5596_L2" | "Nexus7004" | "Nexus7009" )
                        IF_IN_OUT=("ifHCInOctets" "ifHCOutOctets"); IF_ERROR=("ifInErrors" "ifOutErrors"); IF_BROADCAST=("ifHCInBroadcastPkts")
                        CPU=(".1.3.6.1.4.1.9.9.109.1.1.1.1.7.1")
                        MEM=(".1.3.6.1.4.1.9.9.109.1.1.1.1.12.1" ".1.3.6.1.4.1.9.9.109.1.1.1.1.13.1")
                        if [ "${1}" = "Nexus5596_L2" ];then
                                TEMP=(".1.3.6.1.4.1.9.9.91.1.1.1.1.4.21600")
                        else
                                TEMP=(".1.3.6.1.4.1.9.9.91.1.1.1.1.4.21598")
                        fi
                        SESSION=("")
                        PORT=("")
                        ;;
                "C2960S-48TS" )
                        IF_IN_OUT=("ifHCInOctets" "ifHCOutOctets"); IF_ERROR=("ifInErrors" "ifOutErrors"); IF_BROADCAST=("ifHCInBroadcastPkts")
                        CPU=(".1.3.6.1.4.1.9.9.109.1.1.1.1.7.1")
                        MEM=(".1.3.6.1.4.1.9.9.48.1.1.1.5.*" ".1.3.6.1.4.1.9.9.48.1.1.1.6.*")
                        TEMP=(".1.3.6.1.4.1.9.9.13.1.3.1.3.1008")
                        SESSION=("")
                        PORT=("")
                        ;;
                "C3560X-24T" )
                        IF_IN_OUT=("ifHCInOctets" "ifHCOutOctets"); IF_ERROR=("ifInErrors" "ifOutErrors"); IF_BROADCAST=("ifHCInBroadcastPkts")
                        CPU=(".1.3.6.1.4.1.9.9.109.1.1.1.1.7.1")
                        MEM=(".1.3.6.1.4.1.9.9.48.1.1.1.5.1" ".1.3.6.1.4.1.9.9.48.1.1.1.6.1" ".1.3.6.1.4.1.9.9.48.1.1.1.5.2" ".1.3.6.1.4.1.9.9.48.1.1.1.6.2")
                        TEMP=(".1.3.6.1.4.1.9.9.13.1.3.1.3.1006")
                        SESSION=("")
                        PORT=("")
                        ;;
                "C3750X-48T" | "C3750X-24T" )
                        IF_IN_OUT=("ifHCInOctets" "ifHCOutOctets"); IF_ERROR=("ifInErrors" "ifOutErrors"); IF_BROADCAST=("ifHCInBroadcastPkts")
                        CPU=(".1.3.6.1.4.1.9.9.109.1.1.1.1.7.*")
                        MEM=(".1.3.6.1.4.1.9.9.48.1.1.1.5.*" ".1.3.6.1.4.1.9.9.48.1.1.1.6.*")
                        TEMP=(".1.3.6.1.4.1.9.9.13.1.3.1.3.1006")
                        SESSION=("")
                        PORT=("")
                        ;;
                "C4948E" )
                        IF_IN_OUT=("ifHCInOctets" "ifHCOutOctets"); IF_ERROR=("ifInErrors" "ifOutErrors"); IF_BROADCAST=("ifHCInBroadcastPkts")
                        CPU=(".1.3.6.1.4.1.9.9.109.1.1.1.1.7.1")
                        MEM=(".1.3.6.1.4.1.9.9.48.1.1.1.5.1" ".1.3.6.1.4.1.9.9.48.1.1.1.6.1")
                        TEMP=(".1.3.6.1.4.1.9.9.13.1.3.1.3.1" ".1.3.6.1.4.1.9.9.13.1.3.1.3.2")
                        SESSION=("")
                        PORT=("")
                        ;;
                "Cisco892J" )
                        IF_IN_OUT=("ifHCInOctets" "ifHCOutOctets"); IF_ERROR=("ifInErrors" "ifOutErrors"); IF_BROADCAST=("ifHCInBroadcastPkts")
                        CPU=("")
                        MEM=("")
                        TEMP=("")
                        SESSION=("")
                        PORT=("")
                        ;;
                "Cisco3925" )
                        IF_IN_OUT=("ifHCInOctets" "ifHCOutOctets"); IF_ERROR=("ifInErrors" "ifOutErrors"); IF_BROADCAST=("ifHCInBroadcastPkts")
                        CPU=(".1.3.6.1.4.1.9.9.109.1.1.1.1.7.*")
                        MEM=(".1.3.6.1.4.1.9.9.48.1.1.1.5.*" ".1.3.6.1.4.1.9.9.48.1.1.1.6.*")
                        TEMP=(".1.3.6.1.4.1.9.9.13.1.3.1.3.1" ".1.3.6.1.4.1.9.9.13.1.3.1.3.2" ".1.3.6.1.4.1.9.9.13.1.3.1.3.3" ".1.3.6.1.4.1.9.9.13.1.3.1.3.4" ".1.3.6.1.4.1.9.9.13.1.3.1.3.5" ".1.3.6.1.4.1.9.9.13.1.3.1.3.6" ".1.3.6.1.4.1.9.9.13.1.3.1.3.7")
                        SESSION=("")
                        PORT=("")
                        ;;
                "PA-5050" | "PA-5020" |  "PA-4050" )
                        # ※PA-500,PA-4050の2機種のみMEMがある：MEM=(""メモリ   /api/?type=op&cmd=<show><system><resources></resources></system></show>     ※MIBで参照不可のためAPI参照を追加。
                        IF_IN_OUT=("ifHCInOctets" "ifHCOutOctets"); IF_ERROR=("ifInErrors" "ifOutErrors"); IF_BROADCAST=("ifHCInBroadcastPkts")
                        CPU=(".1.3.6.1.2.1.25.3.3.1.2.1" ".1.3.6.1.2.1.25.3.3.1.2.2")
                        MEM=("")
                        TEMP=(".1.3.6.1.2.1.99.1.1.1.4.11" ".1.3.6.1.2.1.99.1.1.1.4.12" ".1.3.6.1.2.1.99.1.1.1.4.13" ".1.3.6.1.2.1.99.1.1.1.4.14")
                        SESSION=(".1.3.6.1.4.1.25461.2.1.2.3.3.0" ".1.3.6.1.4.1.25461.2.1.2.3.4.0" ".1.3.6.1.4.1.25461.2.1.2.3.5.0" ".1.3.6.1.4.1.25461.2.1.2.3.6.0" ".1.3.6.1.4.1.25461.2.1.2.3.1.0")
                        PORT=("")
                        ;;
                 "PA-500" )
                        # ※PA-500はMEMがある：MEM=(""メモリ    /api/?type=op&cmd=<show><system><resources></resources></system></show> ※MIBで参照不可のためAPI参照を追加。
                        IF_IN_OUT=("ifHCInOctets" "ifHCOutOctets"); IF_ERROR=("ifInErrors" "ifOutErrors"); IF_BROADCAST=("ifHCInBroadcastPkts")
                        CPU=(".1.3.6.1.2.1.25.3.3.1.2.1" ".1.3.6.1.2.1.25.3.3.1.2.2")
                        MEM=("")
                        TEMP=(".1.3.6.1.2.1.99.1.1.1.4.3" ".1.3.6.1.2.1.99.1.1.1.4.4")
                        SESSION=(".1.3.6.1.4.1.25461.2.1.2.3.3.0" ".1.3.6.1.4.1.25461.2.1.2.3.4.0" ".1.3.6.1.4.1.25461.2.1.2.3.5.0" ".1.3.6.1.4.1.25461.2.1.2.3.6.0" ".1.3.6.1.4.1.25461.2.1.2.3.1.0")
                        PORT=("")
                        ;;
                 "PA-2020" )
                        # ※PA-2020
                        IF_IN_OUT=("ifHCInOctets" "ifHCOutOctets"); IF_ERROR=("ifInErrors" "ifOutErrors"); IF_BROADCAST=("ifHCInBroadcastPkts")
                        CPU=(".1.3.6.1.2.1.25.3.3.1.2.1" ".1.3.6.1.2.1.25.3.3.1.2.2")
                        MEM=("")
                        TEMP=(".1.3.6.1.2.1.99.1.1.1.4.5" ".1.3.6.1.2.1.99.1.1.1.4.6" ".1.3.6.1.2.1.99.1.1.1.4.7" ".1.3.6.1.2.1.99.1.1.1.4.8")
                        SESSION=(".1.3.6.1.4.1.25461.2.1.2.3.3.0" ".1.3.6.1.4.1.25461.2.1.2.3.4.0" ".1.3.6.1.4.1.25461.2.1.2.3.5.0" ".1.3.6.1.4.1.25461.2.1.2.3.6.0" ".1.3.6.1.4.1.25461.2.1.2.3.1.0")
                        PORT=("")
                        ;;
                "NS-2240-48" )
                        IF_IN_OUT=(""); IF_ERROR=(""); IF_BROADCAST=("")
                        CPU=("")
                        MEM=("")
                        TEMP=(".1.3.6.1.4.1.263.2.1.500.1.1.1.3.1")
                        SESSION=("")
                        PORT=("")
                        ;;
                "BIG-IP1600" | "BIG-IP3900" | "VIPRION2400" )
                        # IF_IN_OUT=("ifHCInOctets" "ifHCOutOctets"); IF_ERROR=("sysInterfaceStatErrorsIn" "sysInterfaceStatErrorsOut"); IF_BROADCAST=("ifHCInBroadcastPkts")
                        IF_IN_OUT=("sysIfxStatHcInOctets" "sysIfxStatHcOutOctets"); IF_ERROR=("sysInterfaceStatErrorsIn" "sysInterfaceStatErrorsOut"); IF_BROADCAST=("sysIfxStatHcInBroadcastPkts")
                        CPU=(".1.3.6.1.4.1.3375.2.1.7.5.2.1.27.*")
                        MEM=(".1.3.6.1.4.1.3375.2.1.1.2.1.44.0" ".1.3.6.1.4.1.3375.2.1.1.2.1.45.0" ".1.3.6.1.4.1.3375.2.1.1.2.1.143.0" ".1.3.6.1.4.1.3375.2.1.1.2.1.144.0")
                        if [ "${1}" = "VIPRION2400" ];then
                                TEMP=(".1.3.6.1.4.1.3375.2.1.3.1.2.1.2.1001")
                        else
                                TEMP=(".1.3.6.1.4.1.3375.2.1.3.2.3.2.1.2.1" ".1.3.6.1.4.1.3375.2.1.3.1.2.1.2.1")
                        fi
                        SESSION=(".1.3.6.1.4.1.3375.2.2.10.2.3.1.12.*" ".1.3.6.1.4.1.3375.2.2.5.4.3.1.11.*" ".1.3.6.1.4.1.3375.2.1.1.2.1.8.0")
                        # "Pool" or "List" or "iRule"
                        SNAT_TYPE=`echo ${SYMBOL}| cut -c 12-`
                        if [ "${SNAT_TYPE}" = "Pool" ];then
                                # ポート数(SNAT Pool)
                                PORT=(".1.3.6.1.4.1.3375.2.2.9.8.3.1.8.*")
                        elif [ "${SNAT_TYPE}" = "List" ];then
                                # ポート数(SNAT List)
                                PORT=(".1.3.6.1.4.1.3375.2.2.9.2.3.1.8.*")
                        else
                                # ポート数(SNAT iRule)
                                PORT=("")
                        fi
                        ;;
                "C4500X-32" | "C4500X-16" )
                        IF_IN_OUT=("ifHCInOctets" "ifHCOutOctets"); IF_ERROR=("ifInErrors" "ifOutErrors"); IF_BROADCAST=("ifHCInBroadcastPkts")
                        CPU=(".1.3.6.1.4.1.9.9.109.1.1.1.1.4.1000")
                        MEM=(".1.3.6.1.4.1.9.9.48.1.1.1.5.1" ".1.3.6.1.4.1.9.9.48.1.1.1.6.1" ".1.3.6.1.4.1.9.9.48.1.1.1.5.2" ".1.3.6.1.4.1.9.9.48.1.1.1.6.2")
                        TEMP=(".1.3.6.1.4.1.9.9.13.1.3.1.3.1" ".1.3.6.1.4.1.9.9.13.1.3.1.3.2" ".1.3.6.1.4.1.9.9.13.1.3.1.3.3" ".1.3.6.1.4.1.9.9.13.1.3.1.3.4" ".1.3.6.1.4.1.9.9.13.1.3.1.3.5" ".1.3.6.1.4.1.9.9.13.1.3.1.3.6")
                        SESSION=("")
                        PORT=("")
                        ;;
                "T3048-LY2" )
                        IF_IN_OUT=("")
                        CPU=(".1.3.6.1.2.1.25.3.3.1.2.768" ".1.3.6.1.2.1.25.3.3.1.2.769")
                        MEM=(".1.3.6.1.4.1.2021.4.6.0")
                        TEMP=(".1.3.6.1.4.1.37538.2.3.1.1.4.1" ".1.3.6.1.4.1.37538.2.3.1.1.4.2" ".1.3.6.1.4.1.37538.2.3.1.1.4.3" ".1.3.6.1.4.1.37538.2.3.1.1.4.4" ".1.3.6.1.4.1.37538.2.3.1.1.4.5")
                        SESSION=("")
                        PORT=("")
                        ;;
                "BigTapController" )
                        IF_IN_OUT=("")
                        CPU=(".1.3.6.1.2.1.25.3.3.1.2.768" ".1.3.6.1.2.1.25.3.3.1.2.769")
                        MEM=(".1.3.6.1.4.1.2021.4.6.0")
                        TEMP=("")
                        SESSION=("")
                        PORT=("")
                        ;;
                * )
                        echo "該当MODELがありません！" | tee -a ${LOG_FILE}
                ;;
        esac
}

# ifHCInOctets,ifHCOutOctets,ifInErrors,ifOutErrorsの処理（sysInterfaceStatErrorsIn、sysInterfaceStatErrorsOutは別）
func_GETTMPL()
{
IFNAMED="${1}"
#count "/"
C=`echo "${IFNAMED}"| sed -e 's@[^/]@@g'`
# return ${#C}

#
KOTEI="";PORTNO="";SUBSLOT="";SLOT_STR="";SLOT="";STRING="";

# 分解なし Fa0など
if [ ${#C} -eq 0 ];then
        KOTEI=${IFNAMED}

# ifName 分解 文字列+スロット/サブスロット/ポート
elif [ ${#C} -eq 1 ];then
        PORTNO=`echo ${IFNAMED} | cut -d'/' -f2`
        SLOT_STR=`echo ${IFNAMED} | cut -d'/' -f1`
        SLOT=`echo ${SLOT_STR} | sed -e "s/^[^0-9]*\([0-9]*\)$/\1/"`
        STRING=`echo ${SLOT_STR} |sed -e "s/\([0-9]*\)$//"`
else
        PORTNO=`echo ${IFNAMED} | cut -d'/' -f3`
        SUBSLOT=`echo ${IFNAMED} | cut -d'/' -f2`
        SLOT_STR=`echo ${IFNAMED} | cut -d'/' -f1`
        SLOT=`echo ${SLOT_STR} | sed -e "s/^[^0-9]*\([0-9]*\)$/\1/"`
        STRING=`echo ${SLOT_STR} |sed -e "s/\([0-9]*\)$//"`
fi

# test ${KOTEI} -eq 0 2>/dev/null;
if [ -z "${KOTEI}" ];then KOTEI="NULL";fi
if [ -z "${STRING}" ];then STRING="NULL";fi
if [ -z "${SLOT}" ];then SLOT=-1;else [ "${SLOT}" -ge 0 ] 2> /dev/null || SLOT=-1;fi
if [ -z "${SUBSLOT}" ];then SUBSLOT=-1;else [ "${SUBSLOT}" -ge 0 ] 2> /dev/null || SUBSLOT=-1;fi
if [ -z "${PORTNO}" ];then PORTNO=-1;else [ "${PORTNO}" -ge 0 ] 2> /dev/null || PORTNO=-1;fi

# MODEL別、ifNameからオンボードを判断
case "${MODEL}" in
        "ASR1002" )
                # ■Gi0,Gi0/0/0～3
                if [ "${KOTEI}" = "Gi0" ] \
                        || ( [ "${STRING}" = "Gi" ] && [ ${SLOT} -eq 0 ] &&  [ ${SUBSLOT} -eq 0 ] && [ ${PORTNO} -ge 0 -a ${PORTNO} -le 3 ] );then
                        T_NAME=${array[0]}
                else
                        T_NAME=${array[8]}
                fi
                ;;
        "Nexus5548_L2" | "Nexus5548_L3" )
                # ■mgmt0,Ethernet1/1～32
                if [ "${KOTEI}" = "mgmt0" ] \
                        || ( [ "${STRING}" = "Ethernet" ] && [ ${SLOT} -eq 1 ] && [ ${PORTNO} -ge 1 -a ${PORTNO} -le 32 ] );then
                        T_NAME=${array[0]}
                else
                        T_NAME=${array[8]}
                fi
                ;;
        "Nexus5596_L2" )
                # ■mgmt0,Ethernet1/1～48
                if [ "${KOTEI}" = "mgmt0" ] \
                        || ( [ "${STRING}" = "Ethernet" ] && [ ${SLOT} -eq 1 ] && [ ${PORTNO} -ge 1 -a ${PORTNO} -le 48 ] );then
                        T_NAME=${array[0]}
                else
                        T_NAME=${array[8]}
                fi
                ;;
        "C2960S-48TS" )
                # ■Fa0,Gi1/0/1～52,Gi2/0/1～52
                if [ "${KOTEI}" = "Fa0" ] \
                        || ( [ "${STRING}" = "Gi" ] && [ ${SLOT} -eq 1 ] &&  [ ${SUBSLOT} -eq 0 ] && [ ${PORTNO} -ge 1 -a ${PORTNO} -le 52 ] ) \
                        || ( [ "${STRING}" = "Gi" ] && [ ${SLOT} -eq 2 ] &&  [ ${SUBSLOT} -eq 0 ] && [ ${PORTNO} -ge 1 -a ${PORTNO} -le 52 ] );then
                        T_NAME=${array[0]}
                else
                        T_NAME=${array[8]}
                fi
                ;;
        "C3560X-24T" )
                # ■Fa0,Gi0/1～24
                if [ "${KOTEI}" = "Fa0" ] \
                        || ( [ "${STRING}" = "Gi" ] && [ ${SLOT} -eq 0 ] && [ ${PORTNO} -ge 1 -a ${PORTNO} -le 24 ] );then
                        T_NAME=${array[0]}
                else
                        T_NAME=${array[8]}
                fi
                ;;
        "C3750X-48T" )
                # ■Fa0,Gi1/0/1～48,Gi2/0/1～48
                if [ "${KOTEI}" = "Fa0" ] \
                        || ( [ "${STRING}" = "Gi" ] && [ ${SLOT} -eq 1 ] &&  [ ${SUBSLOT} -eq 0 ] && [ ${PORTNO} -ge 1 -a ${PORTNO} -le 48 ] ) \
                        || ( [ "${STRING}" = "Gi" ] && [ ${SLOT} -eq 2 ] &&  [ ${SUBSLOT} -eq 0 ] && [ ${PORTNO} -ge 1 -a ${PORTNO} -le 48 ] );then
                        T_NAME=${array[0]}
                else
                        T_NAME=${array[8]}
                fi
                ;;
         "C3750X-24T" )
                # ■Fa0,Gi1/0/1～24,Gi2/0/1～24
                if [ "${KOTEI}" = "Fa0" ] \
                        || ( [ "${STRING}" = "Gi" ] && [ ${SLOT} -eq 1 ] &&  [ ${SUBSLOT} -eq 0 ] && [ ${PORTNO} -ge 1 -a ${PORTNO} -le 24 ] ) \
                        || ( [ "${STRING}" = "Gi" ] && [ ${SLOT} -eq 2 ] &&  [ ${SUBSLOT} -eq 0 ] && [ ${PORTNO} -ge 1 -a ${PORTNO} -le 24 ] );then
                        T_NAME=${array[0]}
                else
                        T_NAME=${array[8]}
                fi
                ;;
        "C4948E" )
                # ■Fa1,Gi1/1～48,Te1/49～52
                if [ "${KOTEI}" = "Fa1" ] \
                        || ( [ "${STRING}" = "Gi" ] && [ ${SLOT} -eq 1 ] && [ ${PORTNO} -ge 1 -a ${PORTNO} -le 48 ] ) \
                        || ( [ "${STRING}" = "Te" ] && [ ${SLOT} -eq 1 ] && [ ${PORTNO} -ge 49 -a ${PORTNO} -le 52 ] ) ;then
                        T_NAME=${array[0]}
                else
                        T_NAME=${array[8]}
                fi
                ;;
        "C4500X-16" )
                # ■Fa1,Te1/1～16
                if [ "${KOTEI}" = "Fa1" ] \
                        || ( [ "${STRING}" = "Te" ] && [ ${SLOT} -eq 1 ] && [ ${PORTNO} -ge 1 -a ${PORTNO} -le 16 ] );then
                        T_NAME=${array[0]}
                else
                        T_NAME=${array[8]}
                fi
                ;;
        "C4500X-32" )
                # ■Fa1,Te1/1～32
                if [ "${KOTEI}" = "Fa1" ] \
                        || ( [ "${STRING}" = "Te" ] && [ ${SLOT} -eq 1 ] && [ ${PORTNO} -ge 1 -a ${PORTNO} -le 32 ] );then
                        T_NAME=${array[0]}
                else
                        T_NAME=${array[8]}
                fi
                ;;
        "Cisco3925" )
                # ■Gi0/0～2
                if [ "${STRING}" = "Gi" ] && [ ${SLOT} -eq 0 ] && [ ${PORTNO} -ge 0 -a ${PORTNO} -le 2 ] ;then
                        T_NAME=${array[0]}
                else
                        T_NAME=${array[8]}
                fi
                ;;
        "VIPRION2400" )
                # "VIPRION2400"はすべてが拡張IF
                T_NAME=${array[8]}
                ;;
        "T3048-LY2" )
                # すべてオンボートとする
                T_NAME=${array[0]}
                ;;
        "BigTapController" )
                # すべてオンボートとする
                T_NAME=${array[0]}
                ;;

        ### ここ以降の機種はオンボードのI/Fのみだが、論理IFがあるのでテンプレート分けるため、以下のようにする。
        "PA-4050" )
                # ■mgmt,ethernet1/1～24
                if [ "${KOTEI}" = "mgmt" ] \
                        || ( [ "${STRING}" = "ethernet" ] && [ ${SLOT} -eq 1 ] && [ ${PORTNO} -ge 1 -a ${PORTNO} -le 24 ] );then
                        T_NAME=${array[0]}
                else
                        T_NAME=${array[8]}
                fi
        ;;
        "PA-500" )
                # ■mgmt,ethernet1/1～8
                if [ "${KOTEI}" = "mgmt" ] \
                        || ( [ "${STRING}" = "ethernet" ] && [ ${SLOT} -eq 1 ] && [ ${PORTNO} -ge 1 -a ${PORTNO} -le 8 ] );then
                        T_NAME=${array[0]}
                else
                        T_NAME=${array[8]}
                fi
        ;;
        "PA-5020" )
                # ■mgmt,ethernet1/1～20
                if [ "${KOTEI}" = "mgmt" ] \
                        || ( [ "${STRING}" = "ethernet" ] && [ ${SLOT} -eq 1 ] && [ ${PORTNO} -ge 1 -a ${PORTNO} -le 20 ] );then
                        T_NAME=${array[0]}
                else
                        T_NAME=${array[8]}
                fi
        ;;
        "PA-5050" )
                # ■mgmt,ethernet1/1～24
                if [ "${KOTEI}" = "mgmt" ] \
                        || ( [ "${STRING}" = "ethernet" ] && [ ${SLOT} -eq 1 ] && [ ${PORTNO} -ge 1 -a ${PORTNO} -le 24 ] );then
                        T_NAME=${array[0]}
                else
                        T_NAME=${array[8]}
                fi
        ;;
        "Cisco892J" )
                # ■Gi0,Fa0～Fa8
                if [ "${KOTEI}" = "Gi0" ] \
                        || echo "${KOTEI}" | grep '^Fa[0-8]$' >/dev/null ;then
                        T_NAME=${array[0]}
                else
                        T_NAME=${array[8]}
                fi
                ;;
        "Arista7050T-52" | "Arista7050S-52" )
                # ■Management1,Ethernet1～52
                if [ "${KOTEI}" = "Management1" ] \
                        || echo "${KOTEI}" | egrep '^Ethernet[1-9]$|^Ethernet[1-4][0-9]$|^Ethernet5[0-2]$' >/dev/null ;then
                        T_NAME=${array[0]}
                else
                        T_NAME=${array[8]}
                fi
        ;;
        "ASA5505" )
                # ■Ethernet0/0～7,Internal-Data0/0～1
                if ( [ "${STRING}" = "Ethernet" ] && [ ${SLOT} -eq 0 ] && [ ${PORTNO} -ge 0 -a ${PORTNO} -le 7 ] ) \
                        || ( [ "${STRING}" = "Internal-Data" ] && [ ${SLOT} -eq 0 ] && [ ${PORTNO} -ge 0 -a ${PORTNO} -le 1 ] );then
                        T_NAME=${array[0]}
                else
                        T_NAME=${array[8]}
                fi
        ;;
        "BIG-IP3900" | "BIG-IP1600" | "NS-2240-48" )
                # ■すべてオンボードI/F
                T_NAME=${array[0]}
        ;;
        * )
                T_NAME=${array[8]}
                ;;
esac
}

func_CSV()
{
    # 引数の展開
    L_TNAME=${1}        # 1個目:テンプレート名
    L_HNAME=${2}        # 2個目:ホスト名
    L_NOID=${3}         # 3個目:OID(数字)
    L_ITEMNAME=${4}     # 4個目:アイテム名
    L_CSVTYPE=${5}      # 5個目:CSV TPYE
    # csv typeから、保存時の計算などを取得しセット
        case "${L_CSVTYPE}" in
                "TYPE1" ) CSVTYPE=("60" "92" "420" "0" "3" "bps" "1" "8" "1")          ;;      # IF通信量        : DELAY="300";  HISTORY="92"; TRENDS="420"; STATUS="0"; VALUE_TYPE="3"; UNITS="bps";      MULTIPLIER="1"; FORMULA="8";    DELTA="1";
                "TYPE2" ) CSVTYPE=("60" "92" "420" "0" "3" "counts" "0" "0" "2")       ;;  # IFエラーカウンタ: DELAY="300";  HISTORY="92"; TRENDS="420"; STATUS="0"; VALUE_TYPE="3"; UNITS="counts";   MULTIPLIER="0"; FORMULA="0";    DELTA="2";
                "TYPE3" ) CSVTYPE=("60" "92" "420" "0" "3" "counts" "0" "0" "2")        ;;  # IFﾌﾞﾛｰﾄﾞｷｬｽﾄ    : DELAY="60";  HISTORY="92"; TRENDS="420"; STATUS="0"; VALUE_TYPE="3"; UNITS="counts";   MULTIPLIER="0"; FORMULA="0";    DELTA="2";
                "TYPE4" ) CSVTYPE=("60" "92" "420" "0" "0" "%" "0" "0" "0")                     ;;  # CPUload         : DELAY="60";  HISTORY="92"; TRENDS="420"; STATUS="0"; VALUE_TYPE="0"; UNITS="%";        MULTIPLIER="0"; FORMULA="0";    DELTA="0";
                "TYPE5" ) CSVTYPE=("60" "92" "420" "0" "0" "Byte" "0" "0" "0")          ;;  # MEM1            : DELAY="60";  HISTORY="92"; TRENDS="420"; STATUS="0"; VALUE_TYPE="0"; UNITS="Byte";     MULTIPLIER="0"; FORMULA="0";    DELTA="0";
                "TYPE6" ) CSVTYPE=("60" "92" "420" "0" "0" "Byte" "1" "1024" "0")       ;;  # MEM2 x 1024     : DELAY="60";  HISTORY="92"; TRENDS="420"; STATUS="0"; VALUE_TYPE="0"; UNITS="Byte";     MULTIPLIER="1"; FORMULA="1024"; DELTA="0";
                "TYPE7" ) CSVTYPE=("300" "92" "420" "0" "0" "C" "0" "0" "0")            ;;  # TEMP1           : DELAY="300"; HISTORY="92"; TRENDS="420"; STATUS="0"; VALUE_TYPE="0"; UNITS="C";        MULTIPLIER="0"; FORMULA="0";    DELTA="0";
                "TYPE8" ) CSVTYPE=("300" "92" "420" "0" "0" "C" "1" "0.1" "0")          ;;  # TEMP2 x 0.1     : DELAY="300"; HISTORY="92"; TRENDS="420"; STATUS="0"; VALUE_TYPE="0"; UNITS="C";        MULTIPLIER="1"; FORMULA="0.1";  DELTA="0";
                "TYPE9" ) CSVTYPE=("300" "92" "420" "0" "3" "sessions" "0" "0" "0")     ;;  # SESSION1        : DELAY="300"; HISTORY="92"; TRENDS="420"; STATUS="0"; VALUE_TYPE="3"; UNITS="sessions"; MULTIPLIER="0"; FORMULA="0";    DELTA="0";
                "TYPE10" ) CSVTYPE=("300" "92" "420" "0" "0" "%" "0" "0" "0")           ;;  # SESSION2        : DELAY="300"; HISTORY="92"; TRENDS="420"; STATUS="0"; VALUE_TYPE="0"; UNITS="%";        MULTIPLIER="0"; FORMULA="0";    DELTA="0";
                "TYPE11" ) CSVTYPE=("300" "92" "420" "0" "0" "C" "1" "0.001" "0")       ;;  # TEMP3 x 0.00    : DELAY="300"; HISTORY="92"; TRENDS="420"; STATUS="0"; VALUE_TYPE="0"; UNITS="C";        MULTIPLIER="1"; FORMULA="0.001";  DELTA="0";
                * ) echo "--- Error non CSV type![${L_CSVTYPE}] ---";;
        esac
        # DELAY:更新間隔;HISTORY:ヒストリ;TRENDS:トレンド;STATUS:有効/無効(0:有効,1:無効);VALUE_TYPE=データ型(0:浮動小数,1: 文字列,2:ログ,3:整数,4:テキスト);UNITS=単位;MULTIPLIER=乗数を使用(0:未使用,1:使用);FORMULA=乗数;DELTA=保存時の計算(0:なし,1:差分/時間,2:差分);
    DELAY=${CSVTYPE[0]}; HISTORY=${CSVTYPE[1]}; TRENDS=${CSVTYPE[2]}; STATUS=${CSVTYPE[3]}; VALUE_TYPE=${CSVTYPE[4]}; UNITS=${CSVTYPE[5]}; MULTIPLIER=${CSVTYPE[6]}; FORMULA=${CSVTYPE[7]}; DELTA=${CSVTYPE[8]};

        if [ ${VLAN} -eq 1 ];then
                # del vlan
                if [ `echo $L_ITEMNAME | grep -i "_vl" ` ];then
                        echo "'4','${SNMP_COMMUNITY}','${L_NOID}','161','${L_TNAME}','${L_ITEMNAME}','${L_NOID}','${DELAY}','${HISTORY}','${TRENDS}','','','','${STATUS}','${VALUE_TYPE}','','${UNITS}','${MULTIPLIER}','${DELTA}','','','0','','','${FORMULA}','','0','','','','','','','0','0','','','','','0'" >> ${L_TNAME}.vlan
                else
                        echo "'4','${SNMP_COMMUNITY}','${L_NOID}','161','${L_TNAME}','${L_ITEMNAME}','${L_NOID}','${DELAY}','${HISTORY}','${TRENDS}','','','','${STATUS}','${VALUE_TYPE}','','${UNITS}','${MULTIPLIER}','${DELTA}','','','0','','','${FORMULA}','','0','','','','','','','0','0','','','','','0'" >> ${L_TNAME}.csv
                fi
        else
                echo "'4','${SNMP_COMMUNITY}','${L_NOID}','161','${L_TNAME}','${L_ITEMNAME}','${L_NOID}','${DELAY}','${HISTORY}','${TRENDS}','','','','${STATUS}','${VALUE_TYPE}','','${UNITS}','${MULTIPLIER}','${DELTA}','','','0','','','${FORMULA}','','0','','','','','','','0','0','','','','','0'" >> ${L_TNAME}.csv
        fi
}

func_ROW()
{
        if [ -e ${1} ]; then
            row=`cat ${1} | wc -l`
        return ${row}
        else
                echo "「${1}」ファイルが存在しません。" >> ${LOG_FILE}
    fi
}

func_IF()
{
        # ifHCInOctets,ifHCOutOctets,ifInErrors,ifOutErrors,ifHCInBroadcastPkts の処理(ifNameのindexと取得対象のindex両方あ るもののみ取得)
    if [ ${#} -eq 0 ]; then
        echo "引数が指定されていません!!!" | tee -a ${LOG_FILE}
        return 255
    fi

    # ifName取得
    if [ ! -e ${HOST_NAME}.ifName.txt ];then
            snmpwalk -v ${SNMP_VERSION} -c ${SNMP_COMMUNITY} ${HOST_NAME} ifName >> ${HOST_NAME}.ifName.txt
        fi

for i in ${@};do
        snmpwalk -v ${SNMP_VERSION} -c ${SNMP_COMMUNITY} ${HOST_NAME} ${i} -On >> ${HOST_NAME}.${i}.OID_LIST.txt
    func_ROW "${HOST_NAME}.${i}.OID_LIST.txt"
    echo "COUNT:「${HOST_NAME}」：「${i}」 CSV出力 「${row}」件" >> ${LOG_FILE}
    for n in `seq 1 ${row}`;do
        # oid:oidの数字の部分,  idx:index,      iname:ifNameの名前部分
        oid=`head -n ${n} ${HOST_NAME}.${i}.OID_LIST.txt | tail -1 | cut -d' ' -f1`
        idx=`echo ${oid} | sed -e "s/.*\.\([^.]*\)\$/\1/g"`
        iname=`cat ${HOST_NAME}.ifName.txt | grep "\.${idx} " | cut -d' ' -f4`
        if [ -z "${iname}" ];then
                echo "${HOST_NAME} ${i} ${oid} index:${iname}に該当するifNameがありません。" >> ${LOG_FILE}
        else
            if  [ "${array[7]}" = "Y" ] && ( [ ${i} = "ifInErrors" ] || [ ${i} = "ifOutErrors" ] ) ;then
                ITEM_NAME="${i}_${iname}";
                func_GETTMPL "${iname}";
                func_CSV ${T_NAME} ${HOST_NAME} ${oid} ${ITEM_NAME} TYPE2
            elif [ "${array[13]}" = "Y" ] && [ ${i} = "ifHCInBroadcastPkts" ];then
                ITEM_NAME="${i}_${iname}";
                func_CSV ${array[8]} ${HOST_NAME} ${oid} ${ITEM_NAME} TYPE3
            elif [ "${array[6]}" = "Y" ];then
                # ifHCInOctets,ifHCOutOctets
                ITEM_NAME="${i}_${iname}";
                func_GETTMPL "${iname}";
                func_CSV ${T_NAME} ${HOST_NAME} ${oid} ${ITEM_NAME} TYPE1
            fi
        fi
    done
done
}

func_F5_IF()
{
        # "BIG-IP1600" | "BIG-IP3900" | "VIPRION2400" の3機種の場合(sysIfxStatHcInOctets,sysIfxStatHcOutOctets,sysInterfaceStatErrorsIn,sysInterfaceStatErrorsOut)
    if [ ${#} -eq 0 ]; then
        echo "引数が指定されていません!!!" | tee -a ${LOG_FILE}
        return 255
    fi

    # get Name,OID
for i in ${@};do
    snmpwalk -v ${SNMP_VERSION} -c ${SNMP_COMMUNITY} ${HOST_NAME} ${i} -On | cut -d' ' -f1 >> ${HOST_NAME}.${i}.OID_LIST.txt

    # sysInterfaceStatName取得
    if [ ! -e ${HOST_NAME}.sysInterfaceStatName.txt ];then
            snmpwalk -v ${SNMP_VERSION} -c ${SNMP_COMMUNITY} ${HOST_NAME} sysInterfaceStatName -On >> ${HOST_NAME}.sysInterfaceStatName.txt
        fi
        # sysInterfaceStatName          .1.3.6.1.4.1.3375.2.1.2.4.4.3.1.1
        # sysInterfaceStatErrorsIn      .1.3.6.1.4.1.3375.2.1.2.4.4.3.1.8
        # sysInterfaceStatErrorsOut     .1.3.6.1.4.1.3375.2.1.2.4.4.3.1.9
        # sysIfxStatName                        .1.3.6.1.4.1.3375.2.1.2.4.5.3.1.1               未使用、sysInterfaceStatNameにしている
        # sysIfxStatHcInOctets          .1.3.6.1.4.1.3375.2.1.2.4.5.3.1.6
        # sysIfxStatHcOutOctets         .1.3.6.1.4.1.3375.2.1.2.4.5.3.1.10

        # CSV
        func_ROW "${HOST_NAME}.${i}.OID_LIST.txt"
        echo "COUNT:「${HOST_NAME}」：「${i}」 CSV出力 「${row}」件" >> ${LOG_FILE}
        for n in `seq 1 ${row}`;do
                oid=`head -n ${n} ${HOST_NAME}.${i}.OID_LIST.txt | tail -1`
                idx=`echo ${oid} | cut -d'.' -f17-`
                iname=`cat ${HOST_NAME}.sysInterfaceStatName.txt | grep "\.${idx} " | cut -d' ' -f4`
        ITEM_NAME="${i}_${iname}";
        func_GETTMPL ${iname};
                if [ ${i} = "sysInterfaceStatErrorsIn" ] || [ ${i} = "sysInterfaceStatErrorsOut" ];then
                func_CSV ${T_NAME} ${HOST_NAME} ${oid} ${ITEM_NAME} TYPE2
            elif [ ${i} = "sysIfxStatHcInOctets" ] || [ ${i} = "sysIfxStatHcOutOctets" ];then
                func_CSV ${T_NAME} ${HOST_NAME} ${oid} ${ITEM_NAME} TYPE1
            elif [ ${i} = "sysIfxStatHcInBroadcastPkts" ];then
                func_CSV ${array[8]} ${HOST_NAME} ${oid} ${ITEM_NAME} TYPE3
            fi
        done
done

}

func_CPU()
{
    if [ ${#} -eq 0 ]; then
        echo "引数が指定されていません!!!" | tee -a ${LOG_FILE}
        return 255
    fi

for i in ${@};do
    # snmpwalk or snmpget?
    LAST_C=`echo ${i} | sed -e "s/.*\.\([^.]*\)\$/\1/g"`

    # snmpwalk
    if [ "${LAST_C}" = "*" ];then
        oid=`echo ${i} | sed "s/\.\*//g"`
        snmpwalk -v ${SNMP_VERSION} -c ${SNMP_COMMUNITY} ${HOST_NAME} ${oid} -On >> ${HOST_NAME}.CPU${oid}.txt
                # 正常取得判断
                if cat ${HOST_NAME}.CPU${oid}.txt | grep "No " ; then echo "ホスト名：【${HOST_NAME}】 OID：【${i}】 取得失 敗" |tee -a ${LOG_FILE};
                else
                cat ${HOST_NAME}.CPU${oid}.txt | cut -d' ' -f1 >> ${HOST_NAME}.CPU${oid}.NumberList.txt

                # CSV出力
                func_ROW "${HOST_NAME}.CPU${oid}.NumberList.txt"
                echo "COUNT:「${array[0]}」：「${HOST_NAME}」：「${i}」 CSV出力 「${row}」件" >> ${LOG_FILE}
                for n in `cat ${HOST_NAME}.CPU${oid}.NumberList.txt`;do
                    iName=`grep -w ${n} ${ITEM_NAME_FILE} |cut -f2`
                    if [ -z "${iName}" ];then
                        echo "アイテム名がありません。アイテム名を決めてください。ホスト名：【${HOST_NAME}】OID:【${n}】" | tee -a ${LOG_FILE}
                        echo "アイテム名に「■ITEM_NAME■」をセットします。" | tee -a ${LOG_FILE}
                        ITEM_NAME="■ITEM_NAME■"
                    else
                        ITEM_NAME=${iName}
                    fi
                    func_CSV ${array[0]} ${HOST_NAME} ${n} ${ITEM_NAME} TYPE4
                done
        fi
    else
        #snmpget
        snmpget -v ${SNMP_VERSION} -c ${SNMP_COMMUNITY} ${HOST_NAME} ${i} -On >> ${HOST_NAME}.CPU${i}.txt
            # error判断
            if tail -1 ${HOST_NAME}.CPU${i}.txt | grep "No " ; then
                echo "ホスト名：【${HOST_NAME}】 OID：【${i}】 取得失敗" | tee -a ${LOG_FILE}
            else
                echo "COUNT:「${array[0]}」：「${HOST_NAME}」：「${i}」 CSV出力 「1」件" >> ${LOG_FILE}
                iName=`grep -w ${i} ${ITEM_NAME_FILE} |cut -f2`
                if [ -z "${iName}" ];then
                    echo "アイテム名がありません。アイテム名を決めてください。ホスト名：【${HOST_NAME}】OID:【${i}】" | tee -a ${LOG_FILE}
                    echo "アイテム名に「■ITEM_NAME■」をセットします。" | tee -a ${LOG_FILE}
                    ITEM_NAME="■ITEM_NAME■"
                else
                        ITEM_NAME=${iName}
                fi
                func_CSV ${array[0]} ${HOST_NAME} ${i} ${ITEM_NAME} TYPE4
            fi
    fi
done
}

func_MEM()
{
    if [ ${#} -eq 0 ]; then
        echo "引数が指定されていません!!!" | tee -a ${LOG_FILE}
        return 255
    fi

for i in ${@};do
    # snmpwalk or snmpget?
    LAST_C=`echo ${i} | sed -e "s/.*\.\([^.]*\)\$/\1/g"`

    # snmpwalk
    if [ "${LAST_C}" = "*" ];then
        oid=`echo ${i} | sed "s/\.\*//g"`
        snmpwalk -v ${SNMP_VERSION} -c ${SNMP_COMMUNITY} ${HOST_NAME} ${oid} -On >> ${HOST_NAME}.MEM${oid}.txt
        # 正常取得判断
        if cat ${HOST_NAME}.MEM${oid}.txt | grep "No " ; then echo "ホスト名：【${HOST_NAME}】 OID：【${i}】 取得失敗" |tee -a ${LOG_FILE};
        else
                cat ${HOST_NAME}.MEM${oid}.txt | cut -d' ' -f1 >> ${HOST_NAME}.MEM${oid}.NumberList.txt

                func_ROW "${HOST_NAME}.MEM${oid}.NumberList.txt"
                echo "COUNT:「${array[0]}」：「${HOST_NAME}」：「${i}」 CSV出力 「${row}」件" >> ${LOG_FILE}
                for n in `cat ${HOST_NAME}.MEM${oid}.NumberList.txt`;do
                                # アイテム名設定
                    iName=`grep -w ${n} ${ITEM_NAME_FILE} |cut -f2`
                    if [ -z "${iName}" ];then
                        echo "アイテム名がありません。アイテム名を決めてください。ホスト名：【${HOST_NAME}】OID：【${n}】" | tee -a ${LOG_FILE}
                        echo "アイテム名に「■ITEM_NAME■」をセットします。" | tee -a ${LOG_FILE}
                        ITEM_NAME="■ITEM_NAME■"
                    else
                        ITEM_NAME=${iName}
                    fi

                                # CSV出力
                    # Arista7050T-52 Arista7050S-52 は値に乗数1024を使用(値 x hrStorageAllocationUnits(1024)の設定値)
                    if [ ${MODEL} = "Arista7050T-52" ] || [ ${MODEL} = "Arista7050S-52" ] ;then
                        func_CSV ${array[0]} ${HOST_NAME} ${n} ${ITEM_NAME} TYPE6
                    else
                        func_CSV ${array[0]} ${HOST_NAME} ${n} ${ITEM_NAME} TYPE5
                    fi
                done
        fi
    else
        #snmpget
        snmpget -v ${SNMP_VERSION} -c ${SNMP_COMMUNITY} ${HOST_NAME} ${i} -On >> ${HOST_NAME}.MEM${i}.txt
        # error判断
        if tail -1 ${HOST_NAME}.MEM${i}.txt | grep "No " ; then
            echo "ホスト名：【${HOST_NAME}】 OID：【${i}】 取得失敗" | tee -a ${LOG_FILE}
        else
                echo "COUNT:「${array[0]}」：「${HOST_NAME}」：「${i}」 CSV出力 「1」件" >> ${LOG_FILE}
            iName=`grep -w ${i} ${ITEM_NAME_FILE} |cut -f2`
            if [ -z "${iName}" ];then
                echo "アイテム名がありません。アイテム名を決めてください。ホスト名：【${HOST_NAME}】OID:【${i}】" | tee -a ${LOG_FILE}
                echo "アイテム名に「■ITEM_NAME■」をセットします。" | tee -a ${LOG_FILE}
                ITEM_NAME="■ITEM_NAME■"
            else
                ITEM_NAME=${iName}
            fi

            # edit CSV
            # Arista7050T-52 Arista7050S-52 は値に乗数1024を使用(値 x hrStorageAllocationUnits(1024)の設定値)
            if [ ${MODEL} = "Arista7050T-52" ] || [ ${MODEL} = "Arista7050S-52" ] ;then
                func_CSV ${array[0]} ${HOST_NAME} ${i} ${ITEM_NAME} TYPE6
               ## 以下のOIDの場合、単位がKになる。
            elif [ ${i} = ".1.3.6.1.4.1.3375.2.1.1.2.1.143.0" ] || [ ${i} = ".1.3.6.1.4.1.3375.2.1.1.2.1.144.0" ] || [ ${i} = ".1.3.6.1.4.1.9.9.109.1.1.1.1.12.1" ] || [ ${i} = ".1.3.6.1.4.1.9.9.109.1.1.1.1.13.1" ] ;then
                func_CSV ${array[0]} ${HOST_NAME} ${i} ${ITEM_NAME} TYPE6
            else
                func_CSV ${array[0]} ${HOST_NAME} ${i} ${ITEM_NAME} TYPE5
            fi
        fi

    fi
done
}

func_TEMP()
{
    if [ ${#} -eq 0 ]; then
        echo "引数が指定されていません!!!" | tee -a ${LOG_FILE}
        return 255
    fi

for i in ${@};do
    # snmpwalk or snmpget?
    LAST_C=`echo ${i} | sed -e "s/.*\.\([^.]*\)\$/\1/g"`

    # snmpwalk
    if [ "${LAST_C}" = "*" ];then
        oid=`echo ${i} | sed "s/\.\*//g"`
        snmpwalk -v ${SNMP_VERSION} -c ${SNMP_COMMUNITY} ${HOST_NAME} ${oid} -On >> ${HOST_NAME}.TEMP${oid}.txt
            # 正常取得判断
        if cat ${HOST_NAME}.TEMP${oid}.txt | grep "No "; then echo "ホスト名：【${HOST_NAME}】 OID：【${i}】 取得失敗" |tee -a ${LOG_FILE};
        else
                cat ${HOST_NAME}.TEMP${oid}.txt | cut -d' ' -f1 >> ${HOST_NAME}.TEMP${oid}.NumberList.txt

                # CSV出力
                func_ROW "${HOST_NAME}.TEMP${oid}.NumberList.txt"
                echo "COUNT:「${array[0]}」：「${HOST_NAME}」：「${i}」 CSV出力 「${row}」件" >> ${LOG_FILE}
                for n in `cat ${HOST_NAME}.TEMP${oid}.NumberList.txt`;do
                    iName=`grep -w ${n} ${ITEM_NAME_FILE} |cut -f2`
                    if [ -z "${iName}" ];then
                        echo "アイテム名がありません。アイテム名を決めてください。ホスト名：【${HOST_NAME}】OID：【${n}】" | tee -a ${LOG_FILE}
                        echo "アイテム名に「■ITEM_NAME■」をセットします。" | tee -a ${LOG_FILE}
                        ITEM_NAME="■ITEM_NAME■"
                    else
                        ITEM_NAME=${iName}
                    fi

                    # Arista7050S-52 と Arista7050T-52 は値に0.1をかける(取得した値が10をかけた値である、例：温度:23.5 取得 値:235 になる)
                    if [ ${MODEL} = "Arista7050S-52" ] || [ ${MODEL} = "Arista7050T-52" ] ;then
                        func_CSV ${array[0]} ${HOST_NAME} ${n} ${ITEM_NAME} TYPE8
                    elif [ ${MODEL} = "T3048-LY2" ]; then
                        # T3048-LY2機種の温度は値に0.001をかけて保存する。
                        func_CSV ${array[0]} ${HOST_NAME} ${n} ${ITEM_NAME} TYPE11
                    else
                        func_CSV ${array[0]} ${HOST_NAME} ${n} ${ITEM_NAME} TYPE7
                    fi
                done
        fi
    else
        #snmpget
        snmpget -v ${SNMP_VERSION} -c ${SNMP_COMMUNITY} ${HOST_NAME} ${i} -On >> ${HOST_NAME}.TEMP${i}.txt
            # error判断
        if tail -1 ${HOST_NAME}.TEMP${i}.txt | grep "No " ; then
            echo "ホスト名：【${HOST_NAME}】 OID：【${i}】 取得失敗" | tee -a ${LOG_FILE}
        else
                echo "COUNT:「${array[0]}」：「${HOST_NAME}」：「${i}」 CSV出力 「1」件" >> ${LOG_FILE}
            iName=`grep -w ${i} ${ITEM_NAME_FILE} |cut -f2`
            if [ -z "${iName}" ];then
                echo "アイテム名がありません。アイテム名を決めてください。ホスト名：【${HOST_NAME}】OID:【${i}】" | tee -a ${LOG_FILE}
                echo "アイテム名に「■ITEM_NAME■」をセットします。" | tee -a ${LOG_FILE}
                ITEM_NAME="■ITEM_NAME■"
            else
                ITEM_NAME=${iName}
            fi
            # Arista7050S-52 と Arista7050T-52 は値に0.1をかける(取得した値が10をかけた値である、例：温度:23.5 取得値:235 になる)
            if [ ${MODEL} = "Arista7050S-52" ] || [ ${MODEL} = "Arista7050T-52" ] ;then
                func_CSV ${array[0]} ${HOST_NAME} ${i} ${ITEM_NAME} TYPE8
            elif [ ${MODEL} = "T3048-LY2" ]; then
                # T3048-LY2機種の温度は値に0.001をかけて保存する。
                func_CSV ${array[0]} ${HOST_NAME} ${i} ${ITEM_NAME} TYPE11
            else
                func_CSV ${array[0]} ${HOST_NAME} ${i} ${ITEM_NAME} TYPE7
            fi
        fi

    fi
done
}

func_SESSION()
{
        # "BIG-IP1600" | "BIG-IP3900" | "VIPRION2400" 3機種のみからキックされる。さらにsnmpwalk系は、以下の4種類しかサポートしない。
        # ltmVirtualServStatClientCurConns              .1.3.6.1.4.1.3375.2.2.10.2.3.1.12.*
        # ltmPoolMemberStatServerCurConns               .1.3.6.1.4.1.3375.2.2.10.2.3.1.11.*
        # ltmSnatPoolStatServerCurConns                 .1.3.6.1.4.1.3375.2.2.9.8.3.1.8.*                       # PORTに分類
        # ltmSnatStatClientCurConns                             .1.3.6.1.4.1.3375.2.2.9.2.3.1.8.*                       # PORTに分類
        # NameはそれぞれのMIBテーブルにあるが、重複のものがある(ltmPoolMemberStatPoolName)。よって、indexの部分から直接変換 する。

    if [ ${#} -eq 0 ]; then
        echo "引数が指定されていません!!!" | tee -a ${LOG_FILE}
        return 255
    fi
for i in ${@};do

    # snmpwalk or snmpget?
    LAST_C=`echo ${i} | sed -e "s/.*\.\([^.]*\)\$/\1/g"`
    # snmpwalk
    if [ "${LAST_C}" = "*" ];then
        oid=`echo ${i} | sed "s/\.\*//g"`

        # get OID Number
        snmpwalk -v ${SNMP_VERSION} -c ${SNMP_COMMUNITY} ${HOST_NAME} ${oid} -On | cut -d' ' -f1 >> ${HOST_NAME}.SESSION${oid}.Number.txt
        # 正常取得判断
        if cat ${HOST_NAME}.SESSION${oid}.Number.txt | grep "No ";then echo "${HOST_NAME} 【${i}】 取得失敗" | tee -a ${LOG_FILE};
        else
                snmpwalk -v ${SNMP_VERSION} -c ${SNMP_COMMUNITY} ${HOST_NAME} ${oid} >> ${HOST_NAME}.SESSION${oid}.txt

                if [ ${oid} = ".1.3.6.1.4.1.3375.2.2.10.2.3.1.12" ];then
                    # edit Name #■ltmVirtualServStatClientCurConns(.1.3.6.1.4.1.3375.2.2.10.2.3.1.12.*)
                    cat ${HOST_NAME}.SESSION${oid}.txt | cut -d'"' -f2 >> ${HOST_NAME}.SESSION${oid}.Name.txt
                    # 先頭に"ltmVirtualServStatClientCurConns_"を追加
                    # 例：変換前：【bml_FO1_webmail-No050_10080_hvs_frt】  変換後：【ltmVirtualServStatClientCurConns_bml_FO1_webmail-No050_10080_hvs_frt】
                    sed -i 's/^/ltmVirtualServStatClientCurConns_/g' ${HOST_NAME}.SESSION${oid}.Name.txt

                        # edit CSV
                        func_ROW "${HOST_NAME}.SESSION${oid}.Number.txt"
                        echo "COUNT:「${array[0]}」：「${HOST_NAME}」：「${i}」 CSV出力 「${row}」件" >> ${LOG_FILE}
                        for n in `seq 1 ${row}`;do
                                noid=`head -n ${n} ${HOST_NAME}.SESSION${oid}.Number.txt|tail -1`
                                ITEM_NAME=`head -n ${n} ${HOST_NAME}.SESSION${oid}.Name.txt|tail -1`
                                func_CSV ${array[8]} ${HOST_NAME} ${noid} ${ITEM_NAME} TYPE9
                        done

                elif  [ ${oid} = ".1.3.6.1.4.1.3375.2.2.5.4.3.1.11" ] ;then
                        # edit Name #■ltmPoolMemberStatServerCurConns(.1.3.6.1.4.1.3375.2.2.5.4.3.1.11.*)
                    cat ${HOST_NAME}.SESSION${oid}.txt | cut -d'"' -f2- | cut -d' ' -f1 >> ${HOST_NAME}.SESSION${oid}.Name.txt
                    # 例：変換前：【pool_rd_3711_BN9017-C0A80906-VC".ipv4z."192.168.9.6%3711】  変換後：【ltmPoolMemberStatServerCurConns_pool_rd_3711_BN9017-C0A80906-VC_ipv4z_192_168_9_6_3711】
                    sed -i -e 's/^/ltmPoolMemberStatServerCurConns_/g' -e 's/"//g' -e 's/\./_/g' -e 's/\%/_/g' ${HOST_NAME}.SESSION${oid}.Name.txt

                        # edit CSV
                        func_ROW "${HOST_NAME}.SESSION${oid}.Number.txt"
                        echo "COUNT:「${array[0]}」：「${HOST_NAME}」：「${i}」 CSV出力 「${row}」件" >> ${LOG_FILE}
                        for n in `seq 1 ${row}`;do
                                noid=`head -n ${n} ${HOST_NAME}.SESSION${oid}.Number.txt|tail -1`
                                ITEM_NAME=`head -n ${n} ${HOST_NAME}.SESSION${oid}.Name.txt|tail -1`
                                func_CSV ${array[8]} ${HOST_NAME} ${noid} ${ITEM_NAME} TYPE9
                        done

                elif [ ${oid} = ".1.3.6.1.4.1.3375.2.2.9.8.3.1.8" ] ;then
                    # edit Name #■ltmSnatPoolStatServerCurConns(.1.3.6.1.4.1.3375.2.2.9.8.3.1.8.*)
                    cat ${HOST_NAME}.SESSION${oid}.txt | cut -d'"' -f2 >> ${HOST_NAME}.SESSION${oid}.Name.txt
                    # 先頭に"ltmSnatPoolStatServerCurConns_"を追加
                    sed -i 's/^/ltmSnatPoolStatServerCurConns_/g' ${HOST_NAME}.SESSION${oid}.Name.txt

                        # edit CSV
                        func_ROW "${HOST_NAME}.SESSION${oid}.Number.txt"
                        echo "COUNT:「${array[8]}」：「${HOST_NAME}」：「${i}」 CSV出力 「${row}」件" >> ${LOG_FILE}
                        for n in `seq 1 ${row}`;do
                                noid=`head -n ${n} ${HOST_NAME}.SESSION${oid}.Number.txt|tail -1`
                                ITEM_NAME=`head -n ${n} ${HOST_NAME}.SESSION${oid}.Name.txt|tail -1`
                                func_CSV ${array[8]} ${HOST_NAME} ${noid} ${ITEM_NAME} TYPE9
                        done

                elif [ ${oid} = ".1.3.6.1.4.1.3375.2.2.9.2.3.1.8" ] ;then
                    # edit Name #■ltmSnatStatClientCurConns(.1.3.6.1.4.1.3375.2.2.9.2.3.1.8.*)
                    cat ${HOST_NAME}.SESSION${oid}.txt | cut -d'"' -f2 >> ${HOST_NAME}.SESSION${oid}.Name.txt
                    # 先頭に"ltmSnatStatClientCurConns_"を追加
                    sed -i 's/^/ltmSnatStatClientCurConns_/g' ${HOST_NAME}.SESSION${oid}.Name.txt

                        # edit CSV
                        func_ROW "${HOST_NAME}.SESSION${oid}.Number.txt"
                        echo "COUNT:「${array[8]}」：「${HOST_NAME}」：「${i}」 CSV出力 「${row}」件" >> ${LOG_FILE}
                        for n in `seq 1 ${row}`;do
                                noid=`head -n ${n} ${HOST_NAME}.SESSION${oid}.Number.txt|tail -1`
                                ITEM_NAME=`head -n ${n} ${HOST_NAME}.SESSION${oid}.Name.txt|tail -1`
                                func_CSV ${array[8]} ${HOST_NAME} ${noid} ${ITEM_NAME} TYPE9
                        done

                else
                        echo "■対応しないOIDです。: ${oid}" | tee -a ${LOG_FILE}
                        fi
            fi
    else
    #snmpget
        snmpget -v ${SNMP_VERSION} -c ${SNMP_COMMUNITY} ${HOST_NAME} ${i} | cut -d' ' -f1 >> ${HOST_NAME}.SESSION${i}.txt
        # error判断
        if tail -1 ${HOST_NAME}.SESSION${i}.txt | grep "No " ; then
            echo "ホスト名：【${HOST_NAME}】 OID：【${i}】 取得失敗" | tee -a ${LOG_FILE}
        else
                echo "COUNT:「${array[0]}」：「${HOST_NAME}」：「${i}」 CSV出力 「1」件" >> ${LOG_FILE}
            noid=${i}
            iName=`grep -w ${i} ${ITEM_NAME_FILE} |cut -f2`
            if [ -z "${iName}" ];then
                echo "アイテム名がありません。アイテム名を決めてください。ホスト名：【${HOST_NAME}】OID：【${i}】" | tee -a ${LOG_FILE}
                echo "アイテム名に「■ITEM_NAME■」をセットします。" | tee -a ${LOG_FILE}
                ITEM_NAME="■ITEM_NAME■"
            else
                ITEM_NAME="${iName}"
            fi
            if [ ${i} = ".1.3.6.1.4.1.25461.2.1.2.3.1.0" ];then
                # セッション使用率(パーセント))（筐体）
                func_CSV ${array[0]} ${HOST_NAME} ${i} ${ITEM_NAME} TYPE10
            else
                func_CSV ${array[0]} ${HOST_NAME} ${i} ${ITEM_NAME} TYPE9
            fi
        fi
    fi
done
}

###################################### main ######################################
MASTER_FILE="HOSTLIST.txt"
ITEM_NAME_FILE="ITEMNAME.txt"
LOG_FILE="joblog.log"
SNMP_COMMUNITY="XXXXXXX"
SNMP_VERSION="2c"
VLAN="1" # 1:取得しない

echo "処理開始！`date`" | tee -a ${LOG_FILE}

func_ROW "${MASTER_FILE}"
STEP=${row}
for list in `seq 1 ${row}`;do
    PARM=`head -$list ${MASTER_FILE} | tail -1`
    array=(${PARM})
    HOST_NAME=${array[17]}
    MODEL=${array[19]}
    SYMBOL=${array[20]}
    CSVTYPE=()

    echo "処理開始`date` ${list}／${STEP} 行  パラメータ：${PARM} " | tee -a ${LOG_FILE}

    if [ -z "${HOST_NAME}" ];then
        echo "${MASTER_FILE}から値が取得できません。処理終了。" | tee -a ${LOG_FILE}
        break
    fi

    ping -c 1 ${HOST_NAME} 1>>${LOG_FILE} 2>&1
    if [ ${?} != "0" ];then
        echo "■${HOST_NAME}へのping失敗、次のホストを処理する。" | tee -a ${LOG_FILE}
    else

        # snmp接続できるかチェック
                snmpget -v ${SNMP_VERSION} -c ${SNMP_COMMUNITY} ${HOST_NAME} .1 1>>${LOG_FILE} 2>&1
            if [ "${?}" != "0" ];then
                echo "■${HOST_NAME}へのsnmp接続失敗 、次のホストを処理する。" | tee -a ${LOG_FILE};
        else
                        # OIDをセット
                        func_SETOID "${MODEL}";
                        # CPU
                        if [ "${array[1]}" = "Y" ] ;then
                                if [ "${CPU}" = "" ];then echo "${HOST_NAME} CPU OIDが指定されていません。" | tee -a ${LOG_FILE}; else func_CPU "${CPU[@]}";fi
                        fi
                        # MEM
                if [ "${array[2]}" = "Y" ] ;then
                        if [ "${MEM}" = "" ];then echo "${HOST_NAME} MEM OIDが指定されていません。" | tee -a ${LOG_FILE}; else func_MEM "${MEM[@]}";fi
                        fi
                # TEMP
                if [ "${array[3]}" = "Y" ] ;then
                        if [ "${TEMP}" = "" ];then echo "${HOST_NAME} TEMP OIDが指定されていません。" | tee -a ${LOG_FILE}; else func_TEMP "${TEMP[@]}";fi
                fi
                # SESSION
                if [ "${array[4]}" = "Y" ] ;then
                        if [ "${SESSION}" = "" ];then echo "${HOST_NAME} SESSION OIDが指定されていません。" | tee -a ${LOG_FILE}; else func_SESSION "${SESSION[@]}";fi
                        fi
                        # IF_IN_OUT
                if [ "${array[6]}" = "Y" ] || [ "${array[11]}" = "Y" ] ;then
                        if [ "${MODEL}" = "BIG-IP1600" ] || [ "${MODEL}" = "BIG-IP3900" ] || [ "${MODEL}" = "VIPRION2400" ];then
                                # "BIG-IP1600" | "BIG-IP3900" | "VIPRION2400" の3機種の場合
                                if [ "${IF_IN_OUT}" = "" ];then echo "${HOST_NAME} IF_IN_OUT OIDが指定されていません。" | tee -a ${LOG_FILE}; else func_F5_IF "${IF_IN_OUT[@]}";fi
                        else
                                if [ "${IF_IN_OUT}" = "" ];then echo "${HOST_NAME} IF_IN_OUT OIDが指定されていません。" | tee -a ${LOG_FILE}; else func_IF "${IF_IN_OUT[@]}";fi
                        fi
                        fi
                        # IF_ERROR
                if [ "${array[7]}" = "Y" ] || [ "${array[12]}" = "Y" ]  ;then
                        if [ "${MODEL}" = "BIG-IP1600" ] || [ "${MODEL}" = "BIG-IP3900" ] || [ "${MODEL}" = "VIPRION2400" ];then
                                # "BIG-IP1600" | "BIG-IP3900" | "VIPRION2400" の3機種の場合
                                if [ "${IF_ERROR}" = "" ];then echo "${HOST_NAME} IF_ERROR OIDが指定されていません。" | tee -a ${LOG_FILE}; else func_F5_IF "${IF_ERROR[@]}";fi
                        else
                                if [ "${IF_ERROR}" = "" ];then echo "${HOST_NAME} IF_ERROR OIDが指定されていません。" | tee -a ${LOG_FILE}; else func_IF "${IF_ERROR[@]}";fi
                        fi
                        fi
                        # IF_BROADCAST
                if [ "${array[13]}" = "Y" ] ;then
                        if [ "${MODEL}" = "BIG-IP1600" ] || [ "${MODEL}" = "BIG-IP3900" ] || [ "${MODEL}" = "VIPRION2400" ];then
                                # "BIG-IP1600" | "BIG-IP3900" | "VIPRION2400" の3機種の場合
                                if [ "${IF_BROADCAST}" = "" ];then echo "${HOST_NAME} IF_BROADCAST OIDが指定されていません。" | tee -a ${LOG_FILE}; else func_F5_IF "${IF_BROADCAST[@]}";fi
                        else
                                if [ "${IF_BROADCAST}" = "" ];then echo "${HOST_NAME} IF_BROADCAST OIDが指定されていません。" | tee -a ${LOG_FILE}; else func_IF "${IF_BROADCAST[@]}";fi
                        fi
                fi
                # PORT    ("BIG-IP1600" | "BIG-IP3900" | "VIPRION2400" 3機種のみ)
                if [ "${array[14]}" = "Y" ] ;then
                        if [ "${MODEL}" = "BIG-IP1600" ] || [ ${MODEL} = "BIG-IP3900" ] || [ ${MODEL} = "VIPRION2400" ];then
                                # if [ ${PORT} = "" ];then echo "${HOST_NAME} OIDが指定されていません。" | tee -a ${LOG_FILE}; else func_PORT "${PORT[@]}";fi
                                if [ "${PORT}" = "" ];then echo "${HOST_NAME} PORT OIDが指定されていません。" | tee -a ${LOG_FILE}; else func_SESSION "${PORT[@]}";fi
                        else
                                echo "BIG-IP1600, BIG-IP3900, VIPRION2400の3機種にしか対応していません。" | tee -a ${LOG_FILE}
                        fi
                fi
            fi
    fi
done

echo "'type','snmp_community','snmp_oid','snmp_port','hostid','name','key_','delay','history','trends','lastvalue','lastclock','prevvalue','status','value_type','trapper_hosts','units','multiplier','delta','prevorgvalue','snmpv3_securityname','snmpv3_securitylevel','snmpv3_authpassphrase','snmpv3_privpassphrase','formula','error','lastlogsize','logtimefmt','templateid','valuemapid','delay_flex','params','ipmi_sensor','data_type','authtype','username','password','publickey','privatekey','mtime'" > header
for i in `ls *.csv`;
do
        # 重複アイテム削除
        cat ${i} | sort | uniq > TEMP_FILE
        /bin/cp -f TEMP_FILE ${i}
        # add header
        cat header ${i} > TEMP_FILE
        /bin/cp -f TEMP_FILE ${i}
        rm -f TEMP_FILE
done
rm -f header
echo "処理完了！`date`" | tee -a ${LOG_FILE}

