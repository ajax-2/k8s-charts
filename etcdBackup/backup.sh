#!/bin/bash
if [[ -z $endpoints || -z $capath || -z $storagepath ]]; then
  echo \"endpoints capath storagepath must be offered.\"; 
  exit 1; 
fi

# etcd
nowtime=`date +'%Y-%m-%d_%H_%M_%S'`

ETCDCTL_API=3 etcdctl  --endpoints=$endpoints --cacert=$capath/ca.crt --cert=$capath/server.crt --key=$capath/server.key  snapshot save $storagepath/etcdbackup_$nowtime

echo \"etcdbackup_$nowtime\" >> $storagepath/etcd_backup

if [[ `cat $storagepath/etcd_backup |wc -l` -gt 2 ]]; then
  delete_etcd=`head -n 1 $storagepath/etcd_backup`
  rm -rf $storagepath/$delete_etcd
  sed -i \"/$delete_etcd/d\" $storagepath/etcd_backup
fi