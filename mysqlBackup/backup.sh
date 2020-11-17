#!/bin/bash
set -e

if [[ -z ${storagepath} || -z ${mysqlhost} || -z ${mysqlport} || -z ${mysqlpassword} ]]; then
  echo \"storagepath mysqlhost mysqlport mysqlpassword must be offered.\"; 
  exit -1; 
fi

nowtime=`date +'%Y-%m-%d_%H_%M_%S'`

# mysql
for simpleDb in `mysql -h${mysqlhost} -P${mysqlport} -uroot -p${mysqlpassword} -e "show databases;" -B -N|grep -v schema`
do
	echo "备份${simpleDb}"
	mysqldump --force -h${mysqlhost} -P${mysqlport} -uroot -p${mysqlpassword} --databases ${simpleDb} --lock-tables=false --master-data=2 --single-transaction |gzip >  ${storagepath}/mysqlbackup_${simpleDb}-${nowtime}.gz
	echo "${storagepath}/mysqlbackup_${simpleDb}-${nowtime}.gz" >> ${storagepath}/${nowtime}
done

echo "${nowtime}" >> ${storagepath}/mysql_backup.state

if [[ `cat ${storagepath}/mysql_backup.state |wc -l` -gt 3 ]]; then
	file_delete=`head -n 1 ${storagepath}/mysql_backup.state`
	if [ -f ${storagepath}/${file_delete} ];then
		for delete_mysql in `cat ${storagepath}/${file_delete}`
		do
			echo "删除过期备份${delete_mysql}"
			rm -rf ${delete_mysql}
		done
		rm -f ${storagepath}/${file_delete}
	fi
  	sed -i "/${file_delete}/d" ${storagepath}/mysql_backup.state
fi