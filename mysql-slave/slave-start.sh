#!/bin/bash

# 展示slave启动时候的程序
# 先判断是否能正常启动slave,如果能,不做后续处理
# 如果不能,先尝试上次执行的slave命令
# 如果还不行, 先备份从库数据,然后删除从库,再从主库同步数据
# 同步数据后,开启slave备份

# 初始化配置
storage='/backup'
master_info="${storage}/master.info"
nowTime=`date +"%Y-%m-%d_%H:%M:%S"`
status_file="${storage}/status.info"
local_status_file="${storage}/local_status.info"

# 初始化文件
if [[ ! -d ${storage} ]]; then
	mkdir -p ${storage}
fi

if [[ ! -f ${status_file} ]];then
	> ${status_file}
fi

# 判断slave正常启动
until mysql -h 127.0.0.1 -uroot -p$MYSQL_ROOT_PASSWORD -e "SELECT 1"; do echo "测试mysql启动中..."; sleep 5; done

# 判断master正常连接
until mysql -h $MASTER_HOST -u$MASTER_USER -p$MASTER_PASSWORD -P$MASTER_PORT -e "SELECT 1"; do echo "测试master主从用户中..."; sleep 5; done

# 判断slave状态
sql_status=`mysql -h 127.0.0.1 -uroot -p$MYSQL_ROOT_PASSWORD -e "show slave status\G;" |grep Slave_SQL_Running:|awk -F': ' '{print $2}'`
io_status=`mysql -h 127.0.0.1 -uroot -p$MYSQL_ROOT_PASSWORD -e "show slave status\G;"  |grep Slave_IO_Running:|awk -F': ' '{print $2}'`
if [[ "x$sql_status" == "xYes" && "x$io_status" == "xYes" ]];then
	> ${status_file}
	echo "slave状态正确"
else
	# 如果状态文件记录连续超过3次,则判定无法启动
	if [[ `cat ${status_file} |wc -l` -gt 3 ]]; then
		exit 1
	else
		echo $nowTime >> ${status_file}
	fi
	echo "slave状态错误, 启动恢复"
	# 导出主库的数据到本地
	databases=$(mysql -h $MASTER_HOST -uroot -p$MASTER_ROOT_PASSWORD -P$MASTER_PORT -e "show databases;" -B -N|grep -v performance_schema |grep -v information_schema|grep -v sys|tr '\n' ' ')
	mysqldump --force -h $MASTER_HOST -uroot -p$MASTER_ROOT_PASSWORD -P$MASTER_PORT --databases $databases --lock-tables=false --master-data=2 --single-transaction > ${storage}/master_${nowTime}.sql

	# 备份当前数据库出mysql本身信息外的数据
	mysql -h 127.0.0.1 -uroot -p$MYSQL_ROOT_PASSWORD -e "stop slave;"
	local_databases=$(mysql -h 127.0.0.1 -uroot -p$MYSQL_ROOT_PASSWORD -e "show databases;" -B -N|grep -v performance_schema |grep -v information_schema|grep -v mysql|grep -v sys|tr '\n' ' ')
	mysqldump --force -h 127.0.0.1 -uroot -p$MYSQL_ROOT_PASSWORD --databases $local_databases |gzip > ${storage}/${nowTime}.gz
	echo ${nowTime}.gz >> ${local_status_file}
	# 保留三次本地备份
	if [[ `cat ${local_status_file}|wc -l` -gt 3 ]]; then
		delete_local_file=`head -n 1 ${local_status_file}`
		rm -f ${storage}/${delete_local_file}
		sed -i "/${delete_local_file}/d" ${local_status_file}
	fi
	
	# 删除从库的数据
	for db in $local_databases
	do
		mysql -h 127.0.0.1 -uroot -p$MYSQL_ROOT_PASSWORD -e "drop database $db;"
	done

	# 构造master.info
	change_master_info=$(head -n 100 ${storage}/master_${nowTime}.sql |grep -e "-- CHANGE"|tr ';' ' ')
	change_master_info=${change_master_info/-- /}
	echo "$change_master_info,MASTER_HOST=\"$MASTER_HOST\",MASTER_USER=\"$MASTER_USER\",MASTER_PORT=$MASTER_PORT,MASTER_PASSWORD=\"$MASTER_PASSWORD\";" > $master_info
	
	# 导入主库数据到从库中
	mysql -h 127.0.0.1 -uroot -p$MYSQL_ROOT_PASSWORD < ${storage}/master_${nowTime}.sql
	rm -f ${storage}/master_${nowTime}.sql
	
	# 开启同步
	change_master_info=`cat ${master_info}`
	mysql -h 127.0.0.1 -uroot -p$MYSQL_ROOT_PASSWORD -e "$change_master_info"
	mysql -h 127.0.0.1 -uroot -p$MYSQL_ROOT_PASSWORD -e "start slave;"

fi

