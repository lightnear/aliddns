#!/bin/bash
#ddns using aliyun dns
#lightnear
#lightnear@qq.com

now=`date "+%Y-%m-%d %H:%M:%S"`
die () {
    echo $1
    echo aliddns_last_act="$now: failed($1)" >> /var/log/aliddns.log
}

[ "$access_key_id" = "" ] && access_key_id=`awk '/access_key_id/{print $2}' config.ini`
[ "$access_key_secret" = "" ] && access_key_secret=`awk '/access_key_secret/{print $2}' config.ini`
[ "$aliddns_domain" = "" ] && aliddns_domain=`awk '/aliddns_domain/{print $2}' config.ini`
[ "$aliddns_name" = "" ] && aliddns_name=`awk '/aliddns_name/{print $2}' config.ini`
[ "$aliddns_dns" = "" ] && aliddns_dns=`awk '/aliddns_dns/{print $2}' config.ini`
[ "$aliddns_ttl" = "" ] && aliddns_ttl=`awk '/aliddns_ttl/{print $2}' config.ini`

#curl -s v4.ident.me
#curl -s v6.ident.me

[ "$aliddns_curl" = "" ] && aliddns_curl="curl -s v4.ident.me"
ip=`$aliddns_curl 2>&1` || die "$ip"


current_ip=`nslookup $aliddns_name.$aliddns_domain $aliddns_dns 2>&1`

if [ "$?" -eq "0" ]
then
    current_ip=`echo "$current_ip" | grep 'Address 1' | tail -n1 | awk '{print $NF}'`

    if [ "$ip" = "$current_ip" ]
    then
        echo "skipping"
        echo aliddns_last_act="$now: skipped($ip)" >> /var/log/aliddns.log
        continue
    fi
fi

timestamp=`date -u "+%Y-%m-%dT%H%%3A%M%%3A%SZ"`

urlencode() {
    # urlencode <string>
    out=""
    while read -n1 c
    do
        case $c in
            [a-zA-Z0-9._-]) out="$out$c" ;;
            *) out="$out`printf '%%%02X' "'$c"`" ;;
        esac
    done
    echo -n $out
}

enc() {
    echo -n "$1" | urlencode
}

send_request() {
    local args="AccessKeyId=$access_key_id&Action=$1&Format=json&$2&Version=2015-01-09"
    local hash=$(echo -n "GET&%2F&$(enc "$args")" | openssl dgst -sha1 -hmac "$access_key_secret&" -binary | openssl base64)
    curl -s "http://alidns.aliyuncs.com/?$args&Signature=$(enc "$hash")"
}

get_recordid() {
    grep -Eo '"RecordId":"[0-9]+"' | cut -d':' -f2 | tr -d '"'
}

query_recordid() {
    send_request "DescribeSubDomainRecords" "SignatureMethod=HMAC-SHA1&SignatureNonce=$timestamp&SignatureVersion=1.0&SubDomain=$aliddns_name.$aliddns_domain&Timestamp=$timestamp"
}

update_record() {
    send_request "UpdateDomainRecord" "RR=$aliddns_name&RecordId=$1&SignatureMethod=HMAC-SHA1&SignatureNonce=$timestamp&SignatureVersion=1.0&TTL=$aliddns_ttl&Timestamp=$timestamp&Type=A&Value=$ip"
}

add_record() {
    send_request "AddDomainRecord&DomainName=$aliddns_domain" "RR=$aliddns_name&SignatureMethod=HMAC-SHA1&SignatureNonce=$timestamp&SignatureVersion=1.0&TTL=$aliddns_ttl&Timestamp=$timestamp&Type=A&Value=$ip"
}

if [ "$aliddns_record_id" = "" ]
then
    aliddns_record_id=`query_recordid | get_recordid`
fi
if [ "$aliddns_record_id" = "" ]
then
    aliddns_record_id=`add_record | get_recordid`
    echo "added record $aliddns_record_id"
else
    update_record $aliddns_record_id
    echo "updated record $aliddns_record_id"
fi

# save to file
if [ "$aliddns_record_id" = "" ]; then
    # failed
    #dbus ram aliddns_last_act="$now: failed"
    echo "$now: aliddns_last_act: failed" >> /var/log/aliddns.log
else
    #dbus ram aliddns_record_id=$aliddns_record_id
    #dbus ram aliddns_last_act="$now: success($ip)"
    echo "$now: aliddns_last_act: success($ip)" >> /var/log/aliddns.log
fi
