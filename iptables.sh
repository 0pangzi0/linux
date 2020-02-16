#!/bin/bash
###################################
#update     2013/11/19  for dynamic IP
#function    iptables config
 
# touch /root/sh/iptables.sh; chmod u+x /root/sh/iptables.sh
##################################
 
######### ENV ####################
 
export LANG=C
export LC_ALL=C
export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
# env_over
 
 
###### filter table ################
 
###### INPUT chains ######
iptables -P INPUT ACCEPT
iptables -P OUTPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -F
iptables -X
 
iptables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -p icmp -m icmp --icmp-type any -m limit --limit 40/s -j ACCEPT

iptables -t nat -A POSTROUTING -s 10.10.12.0/24 -o eth0 -j MASQUERADE
iptables -A FORWARD -s 10.10.12.0/24 -j ACCEPT
 


iptables -A INPUT -p tcp  --dport  443 -j ACCEPT
iptables -A INPUT  -p tcp --dport 1723 -j ACCEPT
iptables -A INPUT -p tcp --dport 53 -j ACCEPT
iptables -A INPUT -p tcp --dport 1688 -j ACCEPT

### ssh ###
iptables -A INPUT  -p tcp --dport 22 -j ACCEPT
### global ###
iptables -A INPUT -j REJECT --reject-with icmp-host-prohibited

###### save ####################
iptables-save -c > /etc/sysconfig/iptables
