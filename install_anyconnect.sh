#!/bin/bash

local_ip=`curl http://ip.3322.net`

yum install -y gcc gcc-c++
yum install -y epel-release
yum install -y ocserv
yum install -y nginx
useradd ocserv

soft_path=/root/software

if [ ! -d $soft_path ];then
	mkdir $soft_path
	cd $soft_path
else
	cd $soft_path
fi

wget http://mirrors.66boc.com/linux/vpn/anyconnect/web.conf -o web.conf 
wget http://mirrors.66boc.com/linux/vpn/anyconnect/ocserv.conf -o ocserv.conf 
wget http://mirrors.66boc.com/linux/vpn/anyconnect/iptables.sh -o iptables.sh

chmod +x iptables.sh
cp -f web.conf  /etc/nginx/conf.d/default.conf


mkdir -p /opt/CA/client
cd /opt/CA

######生成 CA 证书
certtool --generate-privkey --outfile ca-key.pem

cat >ca.tmpl <<EOF
cn = "$local_ip"
organization = "Big Corp"
serial = 1
expiration_days = 3650
ca
signing_key
cert_signing_key
crl_signing_key
EOF


certtool --generate-self-signed --load-privkey ca-key.pem \
--template ca.tmpl --outfile ca-cert.pem

######生成本地服务器证书

certtool --generate-privkey --outfile server-key.pem
cat >server.tmpl <<EOF
cn = "$local_ip"
organization = "MyCompany"
serial = 2
expiration_days = 3650
encryption_key
signing_key
tls_www_server
EOF

certtool --generate-certificate --load-privkey server-key.pem \
--load-ca-certificate ca-cert.pem --load-ca-privkey ca-key.pem \
--template server.tmpl --outfile server-cert.pem

cp -f ./server-cert.pem /etc/pki/ocserv/server-cert.pem
cp -f ./server-key.pem  /etc/pki/ocserv/server-key.pem
cp -f ./ca-cert.pem  /etc/pki/ocserv/ca-cert.pem
cp -f /root/software/ocserv.conf /etc/ocserv/ocserv.conf

/root/software/iptables.sh 
###创建用户
###ocpasswd -c /etc/ocserv/ocpasswd username

###配置转发
sysctl_status=`cat /etc/sysctl.conf|grep net.ipv4.ip_forward|grep -v grep |wc -l`

if [ $sysctl_status == 1 ];then

sed -i 's/net.ipv4.ip_forward = 0/net.ipv4.ip_forward = 1/g' /etc/sysctl.conf

else 

echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf

fi

sysctl -p



###测试
###ocserv -c /etc/ocserv/ocserv.conf -f -d 1

/etc/init.d/nginx  start
/usr/sbin/ocserv
/etc/init.d/iptables  start

echo "/etc/init.d/nginx start" >> /etc/rc.d/rc.local
echo "/usr/sbin/ocserv start" >> /etc/rc.d/rc.local

###生成用户证书

####创建用户证书模板user.tmpl
cat >user.tmpl <<EOF
cn = "user"
unit = "student"
uid = "student"
expiration_days = 3650
signing_key
tls_www_client
EOF



####生成用户密钥和证书
certtool --generate-privkey --outfile user-key.pem

certtool --generate-certificate --load-privkey user-key.pem --load-ca-certificate ca-cert.pem --load-ca-privkey ca-key.pem --template user.tmpl --outfile user-cert.pem

openssl pkcs12 -export -inkey user-key.pem -in user-cert.pem -certfile ca-cert.pem -out user.p12

###certtool --to-p12 --load-privkey user-key.pem --pkcs-cipher 3des-pkcs12 --load-certificate user-cert.pem --outfile user.p12 --outder
cp -f /opt/CA/user.p12 /opt/CA/client/



