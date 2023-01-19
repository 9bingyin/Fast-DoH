#!/usr/bin/env bash

Green="\033[32m"
Font="\033[0m"
Blue="\033[33m"

VERSION=$(curl -s https://api.github.com/repos/AdguardTeam/dnsproxy/releases/latest | grep tag_name | cut -d '"' -f 4)

rootness(){
    if [[ $EUID -ne 0 ]]; then
       echo "Error:This script must be run as root!" 1>&2
       exit 1
    fi
}

checkos(){
    if [[ -f /etc/redhat-release ]];then
        OS=CentOS
    elif cat /etc/issue | grep -q -E -i "debian";then
        OS=Debian
    elif cat /etc/issue | grep -q -E -i "ubuntu";then
        OS=Ubuntu
    elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat";then
        OS=CentOS
    elif cat /proc/version | grep -q -E -i "debian";then
        OS=Debian
    elif cat /proc/version | grep -q -E -i "ubuntu";then
        OS=Ubuntu
    elif cat /proc/version | grep -q -E -i "centos|red hat|redhat";then
        OS=CentOS
    else
        echo "Not supported OS, Please reinstall OS and try again."
        exit 1
    fi
}

get_arch(){
get_arch=`arch`
    if [[ $get_arch =~ "x86_64" ]];then
       ARCHV=amd64
    elif [[ $get_arch =~ "aarch64" ]];then
       ARCHV=arm64
    elif [[ $get_arch =~ "mips64" ]];then
       echo "mips64 is not supported"
       exit 1
    else
       echo "Unknown Architecture!!"
       exit 1
    fi
}

disable_selinux(){
    if [ -s /etc/selinux/config ] && grep 'SELINUX=enforcing' /etc/selinux/config; then
        sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
        setenforce 0
    fi
}

install(){
    echo -e "${Green}即将安装...${Font}"
    if [ "${OS}" == 'CentOS' ];then
        yum install epel-release -y
        yum install -y wget curl tar
        wget "https://github.com/AdguardTeam/dnsproxy/releases/download/${VERSION}/dnsproxy-linux-${ARCHV}-${VERSION}.tar.gz" -O /tmp/dnsproxy.tar.gz
        tar -xzvf /tmp/dnsproxy.tar.gz -C /tmp/
        mv /tmp/linux-${ARCHV}/dnsproxy /usr/bin/dnsproxy
        chmod +x /usr/bin/dnsproxy
        rm -rf /tmp/dnsproxy.tar.gz /tmp/linux-${ARCHV}/
    else
        apt-get -y update
        apt-get install -y wget curl tar
        wget "https://github.com/AdguardTeam/dnsproxy/releases/download/${VERSION}/dnsproxy-linux-${ARCHV}-${VERSION}.tar.gz" -O /tmp/dnsproxy.tar.gz
        tar -xzvf /tmp/dnsproxy.tar.gz -C /tmp/
        mv /tmp/linux-${ARCHV}/dnsproxy /usr/bin/dnsproxy
        chmod +x /usr/bin/dnsproxy
        rm -rf /tmp/dnsproxy.tar.gz /tmp/linux-${ARCHV}/
    fi
}

tips(){
    echo -e "${Green}done!${Font}"
    echo -e "${Blue}请将 /etc/resolv.conf 改为 nameserver 127.0.0.1${Font}"
    echo -e "${Blue}可使用 bash <(curl -sSL "https://raw.githubusercontent.com/9bingyin/Fast-DoH/master/lockdns.sh") 锁定DNS${Font}"
    echo -e "${Blue}如遇53端口占用请查看 https://www.moeelf.com/archives/270.html 或卸载其他 DNS 程序${Font}"
}

main(){
    rootness
    checkos
    get_arch
    disable_selinux
    install
}

dnspod(){
    main
    wget -O /etc/systemd/system/dnsproxy.service https://raw.githubusercontent.com/9bingyin/Fast-DoH/master/services/dnspod.service
    systemctl daemon-reload
    systemctl restart dnsproxy
    systemctl enable dnsproxy
    tips
}

aliyun(){
    main
    wget -O /etc/systemd/system/dnsproxy.service https://raw.githubusercontent.com/9bingyin/Fast-DoH/master/services/aliyun.service
    systemctl daemon-reload
    systemctl restart dnsproxy
    systemctl enable dnsproxy
    tips
}

cloudflare(){
    main
    wget -O /etc/systemd/system/dnsproxy.service https://raw.githubusercontent.com/9bingyin/Fast-DoH/master/services/cloudflare.service
    systemctl daemon-reload
    systemctl restart dnsproxy
    systemctl enable dnsproxy
    tips
}

google(){
    main
    wget -O /etc/systemd/system/dnsproxy.service https://raw.githubusercontent.com/9bingyin/Fast-DoH/master/services/google.service
    systemctl daemon-reload
    systemctl restart dnsproxy
    systemctl enable dnsproxy
    tips
}

dnssb(){
    main
    wget -O /etc/systemd/system/dnsproxy.service https://raw.githubusercontent.com/9bingyin/Fast-DoH/master/services/dnssb.service
    systemctl daemon-reload
    systemctl restart dnsproxy
    systemctl enable dnsproxy
    tips
}

nextdns(){
    main
    wget -O /etc/systemd/system/dnsproxy.service https://raw.githubusercontent.com/9bingyin/Fast-DoH/master/services/nextdns.service
    systemctl daemon-reload
    systemctl restart dnsproxy
    systemctl enable dnsproxy
    tips
}

iqdnseast(){
    main
    wget -O /etc/systemd/system/dnsproxy.service https://raw.githubusercontent.com/9bingyin/Fast-DoH/master/services/iqdnseast.service
    systemctl daemon-reload
    systemctl restart dnsproxy
    systemctl enable dnsproxy
    tips
}

iqdnssouth(){
    main
    wget -O /etc/systemd/system/dnsproxy.service https://raw.githubusercontent.com/9bingyin/Fast-DoH/master/services/iqdnssouth.service
    systemctl daemon-reload
    systemctl restart dnsproxy
    systemctl enable dnsproxy
    tips
}


echo && echo -e "------------------------------
Fast DoH Setup Script
 1. DNSPod (1.12.12.12,120.53.53.53)
 2. Aliyun (223.5.5.5,223.6.6.6)
 3. Cloudflare (1.1.1.1,1.0.0.1)
 4. Google (8.8.8.8,8.8.4.4)
 5. DNS.SB (185.222.222.222,45.11.45.11)
 6. NextDNS (dns.nextdns.io)
 7. IQDNS (cn-east.iqiqzz.com)
 8. IQDNS (cn-south.iqiqzz.com)
------------------------------" && echo
read -e -p " 请输入数字 [1-8]:" num
case "$num" in
	1)
	dnspod
	;;
	2)
	aliyun
	;;
	3)
	cloudflare
	;;
	4)
	google
	;;
	5)
	dnssb
	;;
	6)
	nextdns
	;;
	7)
	iqdnseast
	;;
	8)
	iqdnssouth
	;;
	*)
	echo "请输入正确数字 [1-8]"
	;;
esac
