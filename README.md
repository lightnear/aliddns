# aliddns
ddns using aliyun dns

##config.ini配置说明
```
access_key_id xxx
access_key_secret xxxxx
aliddns_dns 223.5.5.5
aliddns_ttl 600
aliddns_domain baidu.com
aliddns_name test
```

access_key_id 阿里云帐号的AccessKeyID  
access_key_secret 阿里云帐号的AccessKeySecret  
aliddns_dns 查询域名IP时使用的DNS，一般223.5.5.5即可  
aliddns_ttl 设置域名时的TTL值，默认600s，即10min  
aliddns_domain 设置的域名（必须归上面设置的阿里云帐号所有）  
aliddns_name 设置域名的A记录  

##CentOS7 使用方法
```
yum -y install curl bind-utils
chmod +x aliddns.sh
```
使用`crontab -e`加入执行计划，每分钟执行一次
* * * * * /opt/aliddns.sh
