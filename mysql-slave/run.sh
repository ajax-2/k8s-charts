#/!/bin/bash

set -e

echo "输入参数"
echo -n "主节点的地址: "
read MASTERHOST
echo -n "主节点的端口: " 
read MASTERPORT
echo -n "主节点同步的用户名: "
read MASTERUSER
echo -n "主节点同步的密码: "
read MASTERPD
echo -n "主节点root密码: "
read MASTERROOTPD
echo -n "当前节点的密码: "
read LOCALPD

echo "base64 加密"
MASTERHOST=`echo -n $MASTERHOST|base64`
MASTERPORT=`echo -n $MASTERPORT|base64`
MASTERUSER=`echo -n $MASTERUSER|base64`
MASTERPD=`echo -n $MASTERPD|base64`
LOCALPD=`echo -n $LOCALPD|base64`
MASTERROOTPD=`echo -n $MASTERROOTPD|base64`

echo "配置参数"
sed -i "s/MASTERHOST/$MASTERHOST/g" slave/secret.yaml
sed -i "s/MASTERPORT/$MASTERPORT/g" slave/secret.yaml
sed -i "s/MASTERUSER/$MASTERUSER/g" slave/secret.yaml
sed -i "s/MASTERPD/$MASTERPD/g" slave/secret.yaml
sed -i "s/LOCALPD/$LOCALPD/g" slave/secret.yaml
sed -i "s/MASTERROOTPD/$MASTERROOTPD/g" slave/secret.yaml

echo "校验tools空间"
kubectl get ns|grep tools
if [[ `kubectl get ns|grep tools|wc -l` -lt 1 ]]; then
	kubectl create ns tools
fi

echo "创建"
kubectl -ntools apply -f slave
