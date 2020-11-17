使用rsync将数据从一个介质备份到另一个介质, 但是在真正运行的时候需要自己指定路径以及rsync的命令,默认只有从/source 到/dest

使用步骤:
	更新rsync-backup.sh 中的rsync,假设需要远程挂载的,还需要安装挂载的软件,比如nfs等
	更新cronjob中挂载的路径 和 启动频率
	创建cm: kubectl -n tools create cm http-to-https-nginx --from-file default.conf --save-config
	创建cron和pvc<如果有用到>: kubectl -n tools apply -f pvc.yaml && kubectl -n tools apply -f cronjob.yaml