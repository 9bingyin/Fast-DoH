#!/usr/bin/env bash

VERSION=$(curl -s https://api.github.com/repos/AdguardTeam/dnsproxy/releases/latest | grep tag_name | cut -d '"' -f 4) && echo "Latest AdguardTeam dnsproxy version is $VERSION"
Green="\033[32m"
Font="\033[0m"
Blue="\033[33m"

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
        wget "https://github.com/AdguardTeam/dnsproxy/releases/download/${VERSION}/dnsproxy-linux-amd64-${VERSION}.tar.gz" -O /tmp/dnsproxy.tar.gz
        tar -xzvf /tmp/dnsproxy.tar.gz -C /tmp/
        mv /tmp/linux-amd64/dnsproxy /usr/bin/dnsproxy
        chmod +x /usr/bin/dnsproxy
		rm -rf /tmp/dnsproxy.tar.gz /tmp/linux-amd64/
        wget -N -P /etc/systemd/system https://raw.githubusercontent.com/9bingyin/Fast-DoH/master/dnsproxy.service
        systemctl daemon-reload
        systemctl restart dnsproxy
        systemctl enable dnsproxy
        echo -e "${Green}done!${Font}"
    else
        apt-get -y update
        apt-get install -y wget curl tar
        wget "https://github.com/AdguardTeam/dnsproxy/releases/download/${VERSION}/dnsproxy-linux-amd64-${VERSION}.tar.gz" -O /tmp/dnsproxy.tar.gz
        tar -xzvf /tmp/dnsproxy.tar.gz -C /tmp/
        mv /tmp/linux-amd64/dnsproxy /usr/bin/dnsproxy
        chmod +x /usr/bin/dnsproxy
		rm -rf /tmp/dnsproxy.tar.gz /tmp/linux-amd64/
        wget -N -P /etc/systemd/system https://raw.githubusercontent.com/9bingyin/Fast-DoH/master/dnsproxy.service
        systemctl daemon-reload
        systemctl restart dnsproxy
        systemctl enable dnsproxy
        echo -e "${Green}done!${Font}"
    fi
}

tips(){
	echo -e "${Blue}请将 /etc/resolv.conf 改为 nameserver 127.0.0.1${Font}"
	echo -e "${Blue}可使用 bash <(curl -sSL "https://raw.githubusercontent.com/9bingyin/Fast-DoH/master/lockdns.sh") 锁定DNS${Font}"
	echo -e "${Blue}如遇53端口占用请查看 https://www.moeelf.com/archives/270.html 或卸载其他 DNS 程序${Font}"
}

main(){
    rootness
    checkos
    disable_selinux
    install
    tips
}

dnspod(){
	main
}

aliyun(){
	main
	sed -i 's/1.12.12.12/223.5.5.5/g' /etc/systemd/system/dnsproxy.service
}

cloudflare(){
	main
	sed -i 's/1.12.12.12/1.1.1.1/g' /etc/systemd/system/dnsproxy.service
}

google(){
	main
	sed -i 's/1.12.12.12/8.8.8.8/g' /etc/systemd/system/dnsproxy.service
}

dnssb(){
	main
	sed -i 's/1.12.12.12/185.222.222.222/g' /etc/systemd/system/dnsproxy.service
}


echo && echo -e "------------------------------
Fast DoH Setup Script
 1. DNSPod (1.12.12.12)
 2. Aliyun (223.5.5.5)
 3. Cloudflare (1.1.1.1)
 4. Google (8.8.8.8)
 5. DNS.SB (185.222.222.222)
------------------------------" && echo
read -e -p " 请输入数字 [1-5]:" num
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
	*)
	echo "请输入正确数字 [1-5]"
	;;
esac