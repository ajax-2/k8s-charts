#!/bin/bas
# rsync.sh
# 镜像为  bubaoxiaoyu/rsync:ubuntu
# 本地执行命令
# rsync -aqutz 需要备份目录 备份到目录
# 远程执行命令为
#　rsync -aqutz 备份用户@远程ip::备份模块 备份到本机目录 --password-file=密文文件
# 这里默认是本地备份, 且需要备份目录为/source, 备份到的目录为/dest, 且记录结果到/dest/rsync-backup.log, 保留1000条

# 记录日期时间
nowTime=`date +"%Y-%m-%d_%H:%M:%S"`
startTime=`date +"%s"`
source="/source"
dest="/dest"

# 执行命令
rsync -aqutz ${source} ${dest}

# 写日志
result=`echo $?`
endTime=`date +"%s"`
echo "${nowTime} 备份结果: ${result}, 耗费时长 $((endTime - startTime)) 秒!" >> ${dest}/rsync-backup.log

# 清空超出日志
if [[ `cat ${dest}/rsync-backup.log|wc -l` -gt 1000 ]]; then
	old_log=`head -n 1 ${dest}/rsync-backup.log`
	sed -i '/${old_log}/d' ${dest}/rsync-backup.log
fi
