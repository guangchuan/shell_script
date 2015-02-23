#!/bin/bash
################################################################################################
##      スクリプト名    ：backup.sh
##      実行条件        ：-
##      スクリプト概要  ：バックアップおよびFTPサーバへのアップロードを行うスクリプト
##                        バックアップ対象はbackup.listに記載されたものをバックアップを行う。
##                        FTPサーバへのアップロードに関する接続条件(サーバIP、ユーザなど)は
##                        ftp.listを読み込む。
################################################################################################
###
### 01. 変数設定(文字色)
###     確認結果を色分けする際に使用
###
def="\033[0m"
whi="\033[1;37m"
red="\033[31m"
gre="\033[32m"

###
### 01.変数設定
###
# スクリプト格納先
#プロセス名
PS_NAME="iwss"
#プログラム名
PG_NAME="iwss"
#ミドルウェア名
MID_NAME="iwss"

SCRIPT_DIR="/root/script/${MID_NAME}"
# スクリプトログ
SCRIPT_LOG_DIR="${SCRIPT_DIR}/log"
# スクリプトログファイル
SCRIPT_LOG="${SCRIPT_LOG_DIR}/`hostname`_${MID_NAME}_backup_`date +%Y%m%d`.log"
# ログ世代確認用一時ファイル
ROTATE_CHK="${SCRIPT_DIR}/log"
# バックアップ格納先
BACKUP_DIR="${SCRIPT_DIR}/backup"
# バックアップファイル名
BACKUP_FILE="`hostname`_${PS_NAME}-`date +%Y%m%d`.tar.gz"
# バックアップ対象リスト
BACKUP_LIST="${SCRIPT_DIR}/backup.list"
# FTPバックアップ先
REMOTE_DIR=/Server/`hostname`/${PG_NAME}
# FTP接続リスト
FTP_LIST="${SCRIPT_DIR}/ftp.list"
# FTP通信ログ
FTP_LOG="${SCRIPT_DIR}/ftp.log"

{
###
### 戻り値チェック関数
###     <!> 各処理の戻り値をチェックする関数。戻り値が"0"以外はNGとし異常終了する。
###
RETURN_CODE_CHECK() {
        MSG=$1
        if [ ${RETURN_CODE} -eq 0 ];then
                echo -e "${gre}[OK]${def}";
        else
                echo -e "${red}[NG]${def}";
                echo -e "\t\t${MSG}";
                exit 1
        fi
};

###
### ログ世代チェック
###
LOG_CHECK(){
        find ${SCRIPT_LOG_DIR} -type f -mtime +5 | xargs rm -f
}

###*********************************************
###サブ関数
###     <!>メイン関数から呼び出されるサブ関数群
###*********************************************

### バックアップ先のディレクトリチェック関数
###     <!> TAR.GZファイルの格納先となるディレクトリ有無をチェック
###
BACKUP_DIR_CHECK(){
        echo -ne "\t- BACKUP Directory Check..."
        ls -d ${BACKUP_DIR} >/dev/null 2>&1
        RETURN_CODE=${?}
        RETURN_CODE_CHECK "${BACKUP_DIR} not found"
}
###
### バックアップリストの確認関数
###     <!> バックアップ対象となるファイル/ディレクトリが記載されたリスト有無をチェック
###
BACKUP_LIST_CHECK(){
        echo -ne "\t- BACKUP List Check..."
        ls -l ${BACKUP_LIST} >/dev/null 2>&1
        RETURN_CODE=${?}
        RETURN_CODE_CHECK "${BACKUP_LIST} not found"
}
###
### バックアップ対象の確認関数
###     <!> バックアップ対象となるファイル/ディレクトリが存在するかチェック
###
BACKUP_TARGET_CHECK(){
        ###
        ### バックアップリストの確認
        ###
IFS_BACKUP=$IFS
IFS=$'\n'
        echo -e "\t- BACKUP TARGET File/Directory Check"
        for BACKUP in `cat ${BACKUP_LIST} | grep -v "^#"`
        do
                BACKUP=`eval ${BACKUP}`
                echo -ne "\t\t${BACKUP}..."
                ls -l ${BACKUP} >/dev/null 2>&1
                RETURN_CODE=${?}
                RETURN_CODE_CHECK
###             TARGET="${TARGET} ${BACKUP}"
                TARGET="/tmp/`date +%Y%m%d`"
        done
IFS=$IFS_BACKUP
}
###
### FTP用のリストチェックおよび、疎通確認
###     <!> FTPサーバ接続用のリストの有無および、FTPサーバとの疎通をチェック
###
FTP_SERVER_CHECK(){
        ###
        ### FTP Listの確認
        ###
        echo -ne "\t- FTP List Check..."
        ls -l ${FTP_LIST} >/dev/null 2>&1
        RETURN_CODE=${?}
        RETURN_CODE_CHECK "${FTP_LIST} not found"
        source ${FTP_LIST}
        ###
        ### FTPサーバ出力
        ###
        echo -e "\t\t -> FTP Server:${FTP_SERVER}"
        echo -e "\t\t -> Connection User:${FTP_USER}"
        echo -e "\t\t -> UPLOAD File(Local):${BACKUP_DIR}/${BACKUP_FILE}"
        echo -e "\t\t -> UPLOAD Directory(Remote):${REMOTE_DIR}"
        ###
        ### FTP Server との疎通確認
        ###
        echo -ne "\t- FTP Server Check..."
        ping -c 2 ${FTP_SERVER} >/dev/null 2>&1
        RETURN_CODE=${?}
        RETURN_CODE_CHECK "${FTP_SERVER} not Connection"
}

###****************************************************
###メイン関数
###     <!> 本スクリプトで実行される処理のメイン関数群
###****************************************************
### サマリー出力関数
###     <!> バックアップとFTPサーバに関する情報を表示する。
###
SUMMARY(){
        echo -e "==============================="
        echo -e "${red}01.[Summary]${def}"
        echo -e "==============================="
        ###
        ### 01.バックアップのフルパス出力
        ###
        echo -e "\t${red}- BACKUP File${def}"
        echo -e "\t\t -> ${BACKUP_DIR}/${BACKUP_FILE}"

        ###
        ### 02.バックアップ対象の出力
        ###
        echo -e "\t${red}- BACKUP TARGET${def}"
        echo -e "\t\t -> Use Backup List:${BACKUP_LIST}"

        ###
        ### 03.バックアップ　実行コマンド
        ###
        echo -e "\t${red}- Execute Command${def}"
        echo -e "\t\t -> tar cfz ${BACKUP_DIR}/${BACKUP_FILE} ${TARGET}"
}

###
### チェック関数
###     <!> バックアップとFTPサーバへのアップロード前の事前確認を行う。
###
CHECK(){
        echo "==================="
        echo -e "${red}02.[Summary Check]${def}"
        echo "==================="
        BACKUP_DIR_CHECK
        BACKUP_LIST_CHECK
        BACKUP_TARGET_CHECK
        #FTP_SERVER_CHECK
}

###
### バックアップ関数
###     <!> サマリーに出力した内容でバックアップを行う。
###
BACKUP(){
        echo "==================="
        echo -e "${red}03.[Backup Execute]${def}"
        echo "==================="
        echo -ne "\t- Execute Backup ...."
        tar cfz ${BACKUP_DIR}/${BACKUP_FILE} ${TARGET} >/dev/null 2>&1
        RETURN_CODE=${?}
        RETURN_CODE_CHECK;
}

###
### アップロード関数
###     <!> バックアップファイルをFTPサーバへアップロードを行う。
###         アップロード後、ログファイルに"Not Connect"があればNGとする。
###
FTP(){
        echo -e "==============================="
        echo -e "${red}04.[FTP Upload]${def}"
        echo -e "==============================="
        FTP_SERVER_CHECK

        ftp -n ${FTP_SERVER} > ${FTP_LOG} << _END_
                user ${FTP_USER} ${FTP_PASS}
                bin
                lcd ${BACKUP_DIR}
                cd ${REMOTE_DIR}
                put ${BACKUP_FILE}
                bye
_END_
        echo -ne "\t- FTP UPLOAD..."
        cat ${FTP_LOG} | grep "Not connected." >/dev/null 2>&1
        if [ ${?} -eq 0 ];then
                RETURN_CODE=1
        else
                RETURN_CODE=0
        fi
        RETURN_CODE_CHECK "File UPLOAD Failed"
        rm -f ${FTP_LOG}
}

###**********************************************************************************************
### メイン処理
###     <!> 本スクリプトで実行するサマリー出力、事前確認、バックアップ、アップロードの処理を行う
###**********************************************************************************************
echo "<< BIND Config and Zone Backup >>";
echo "Start : `date`";
echo "--------------------------------------------------"
LOG_CHECK
SUMMARY
CHECK
BACKUP
FTP
echo "--------------------------------------------------"
echo "End : `date`";
} | tee ${SCRIPT_LOG}
