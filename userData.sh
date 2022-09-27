#!/bin/bash
#　サーバの設定変更
sed -i 's/^HOSTNAME=[a-zA-Z0-9\.\-]*$/HOSTNAME=EC2-bash/g' /etc/sysconfig/network
hostname EC2-bash
cp /usr/share/zoneonfo/Japan /etc/localtime
sed -i 's|^ZONE=[a-zA-Z0-9\.\"]*$|ZONE="Asia/Tokyo"|g' /etc/sysconfig/clock
echo "LANG=ja_JP.UTF-8" > /etc/sysconfig/i18n

#アパッチインストール(ユーザーデータはルートユーザで実行される)
yum install -y
yum install httpd -y
service httpd start
chkconfig httpd on

#index.htmlの設置
# aws s3 cp s3://udemy-vpc-shige-20220830/index.html /var/www/html/
