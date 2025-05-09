#!/usr/bin/env bash

Green="\033[32m"
Font="\033[0m"
Blue="\033[33m"

VERSION=$(curl -s https://api.github.com/repos/AdguardTeam/dnsproxy/releases/latest | grep tag_name | cut -d '"' -f 4)

# 服务配置模板
SERVICE_TEMPLATE='[Unit]
Description=DNS Proxy Service
Documentation=https://github.com/9bingyin/Fast-DoH
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
Restart=always
ExecStart=/usr/bin/dnsproxy -l 127.0.0.1 -p 53 %s
ExecReload=/usr/bin/dnsproxy -l 127.0.0.1 -p 53 %s

[Install]
WantedBy=multi-user.target'

# DNS 服务配置
declare -A DNS_SERVICES=(
    [dnspod]="-u https://doh.pub/dns-query -b 119.29.29.29:53"
    [aliyun]="-u https://223.5.5.5/dns-query -u https://223.6.6.6/dns-query"
    [cloudflare]="-u https://1.1.1.1/dns-query -u https://1.0.0.1/dns-query"
    [google]="-u https://8.8.8.8/dns-query -u https://8.8.4.4/dns-query"
    [dnssb]="-u https://185.222.222.222/dns-query -u https://45.11.45.11/dns-query"
    [nextdns]="-u https://dns.nextdns.io/dns-query -b 8.8.8.8:53"
)

# 服务选项映射
declare -A SERVICE_OPTIONS=(
    [1]="dnspod"
    [2]="aliyun"
    [3]="cloudflare"
    [4]="google"
    [5]="dnssb"
    [6]="nextdns"
    [7]="custom"
)

# 验证是否为 IP 地址
is_ip() {
    local ip=$1
    local ip_regex="^([0-9]{1,3}\.){3}[0-9]{1,3}$"
    if [[ $ip =~ $ip_regex ]]; then
        local IFS='.'
        local -a octets=($ip)
        for octet in "${octets[@]}"; do
            if [[ "$octet" -gt 255 ]]; then
                return 1
            fi
        done
        return 0
    fi
    return 1
}

# 验证是否为域名
is_domain() {
    local domain=$1
    local domain_regex="^([a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}$"
    [[ $domain =~ $domain_regex ]]
    return $?
}

# 配置自定义 DNS
configure_custom_dns() {
    local dns_args=""
    local bootstrap_dns=""    local primary_dns=""
    local backup_dns=""
    
    echo "请输入 DoH 服务器地址，只需要填写域名或 IP，不需要填写 https:// 和 /dns-query"
    echo "例如：dns.google 或 8.8.8.8"
    read -e -p "请输入主 DNS 服务器地址: " primary_dns
    if [ -z "$primary_dns" ]; then
        echo "主 DNS 服务器地址不能为空"
        exit 1
    fi
      # 询问是否配置备用 DNS
    read -e -p "是否配置备用 DNS 服务器？[y/N]: " configure_backup
    if [[ $configure_backup =~ ^[Yy]$ ]]; then
        echo "请输入备用 DoH 服务器地址，格式同上"
        read -e -p "请输入备用 DNS 服务器地址: " backup_dns
        if [ -z "$backup_dns" ]; then
            echo "备用 DNS 服务器地址不能为空"
            exit 1
        fi
    fi
    
    # 检查主 DNS
    if is_ip "$primary_dns"; then
        dns_args="-u https://${primary_dns}/dns-query"
    elif is_domain "$primary_dns"; then
        read -e -p "请输入 Bootstrap DNS（用于解析 DoH 服务器域名的 DNS，如 8.8.8.8）: " bootstrap_dns
        if [ -z "$bootstrap_dns" ] || ! is_ip "$bootstrap_dns"; then
            echo "请输入有效的 Bootstrap DNS IP 地址"
            exit 1
        fi
        dns_args="-u https://${primary_dns}/dns-query"
    else
        echo "无效的主 DNS 服务器地址"
        exit 1
    fi
    
    # 检查备用 DNS
    if [ -n "$backup_dns" ]; then
        if is_ip "$backup_dns"; then
            dns_args="$dns_args -u https://${backup_dns}/dns-query"
        elif is_domain "$backup_dns"; then
            if [ -z "$bootstrap_dns" ]; then
                read -e -p "请输入 Bootstrap DNS（用于解析 DoH 服务器域名的 DNS，如 8.8.8.8）: " bootstrap_dns
                if [ -z "$bootstrap_dns" ] || ! is_ip "$bootstrap_dns"; then
                    echo "请输入有效的 Bootstrap DNS IP 地址"
                    exit 1
                fi
            fi
            dns_args="$dns_args -u https://${backup_dns}/dns-query"
        else
            echo "无效的备用 DNS 服务器地址"
            exit 1
        fi
    fi
    
    # 如果有 bootstrap DNS，添加到参数中
    if [ -n "$bootstrap_dns" ]; then
        dns_args="$dns_args -b ${bootstrap_dns}:53"
    fi

    DNS_SERVICES[custom]="$dns_args"
}

# 检查是否以 root 身份运行
rootness() {
    if [[ $EUID -ne 0 ]]; then
        echo "错误：此脚本必须以 root 身份运行！" 1>&2
        exit 1
    fi
}

# 检测操作系统
checkos() {
    if [[ -f /etc/redhat-release ]] || cat /etc/issue | grep -q -E -i "centos|red hat|redhat" || cat /proc/version | grep -q -E -i "centos|red hat|redhat"; then
        OS=CentOS
    elif cat /etc/issue | grep -q -E -i "debian" || cat /proc/version | grep -q -E -i "debian"; then
        OS=Debian
    elif cat /etc/issue | grep -q -E -i "ubuntu" || cat /proc/version | grep -q -E -i "ubuntu"; then
        OS=Ubuntu
    else
        echo "不支持的操作系统，请重新安装操作系统后重试。"
        exit 1
    fi
}

# 获取系统架构
get_arch() {
    local arch=$(arch)
    if [[ $arch =~ "x86_64" ]]; then
        ARCHV=amd64
    elif [[ $arch =~ "aarch64" ]]; then
        ARCHV=arm64
    elif [[ $arch =~ "mips64" ]]; then
        echo "不支持 mips64 架构"
        exit 1
    else
        echo "未知架构！"
        exit 1
    fi
}

# 禁用 SELinux
disable_selinux() {
    if [ -s /etc/selinux/config ] && grep 'SELINUX=enforcing' /etc/selinux/config; then
        sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
        setenforce 0
    fi
}

# 安装 dnsproxy
install() {
    echo -e "${Green}即将安装...${Font}"
    if [ "${OS}" == 'CentOS' ]; then
        yum install epel-release -y
        yum install -y curl tar
    else
        apt-get -y update
        apt-get install -y curl tar
    fi
    
    local download_url="https://github.com/AdguardTeam/dnsproxy/releases/download/${VERSION}/dnsproxy-linux-${ARCHV}-${VERSION}.tar.gz"
    curl -L "${download_url}" -o /tmp/dnsproxy.tar.gz || { echo "下载失败，请检查网络！"; exit 1; }
    tar -xzvf /tmp/dnsproxy.tar.gz -C /tmp/ || { echo "解压失败！"; exit 1; }
    mv /tmp/linux-${ARCHV}/dnsproxy /usr/bin/dnsproxy || { echo "移动文件失败！"; exit 1; }
    chmod +x /usr/bin/dnsproxy
    rm -rf /tmp/dnsproxy.tar.gz /tmp/linux-${ARCHV}/
}

# 安装服务并启动
install_service() {
    local service_name=$1
    local dns_args="${DNS_SERVICES[$service_name]}"
    printf "$SERVICE_TEMPLATE" "$dns_args" "$dns_args" > /etc/systemd/system/dnsproxy.service
    systemctl daemon-reload
    systemctl restart dnsproxy
    systemctl enable dnsproxy
}

# 卸载服务
uninstall() {
    echo -e "${Green}正在卸载...${Font}"
    systemctl stop dnsproxy
    systemctl disable dnsproxy
    rm -f /etc/systemd/system/dnsproxy.service
    rm -f /usr/bin/dnsproxy
    systemctl daemon-reload
    echo -e "${Green}卸载完成！${Font}"
}

# 显示完成提示
tips() {
    echo -e "${Green}完成！${Font}"
    echo -e "${Blue}请将 /etc/resolv.conf 改为 nameserver 127.0.0.1${Font}"
    echo -e "${Blue}可使用 bash <(curl -sSL \"https://raw.githubusercontent.com/9bingyin/Fast-DoH/master/lockdns.sh\") 锁定DNS${Font}"
    echo -e "${Blue}如遇53端口占用请查看 https://www.moeelf.com/archives/270.html 或卸载其他 DNS 程序${Font}"
}

# 主安装流程
main() {
    rootness
    checkos
    get_arch
    disable_selinux
    install
}

# 显示菜单
show_menu() {
    echo && echo -e "------------------------------
Fast DoH Setup Script
 1. DNSPod (doh.pub)
 2. Aliyun (223.5.5.5,223.6.6.6)
 3. Cloudflare (1.1.1.1,1.0.0.1)
 4. Google (8.8.8.8,8.8.4.4)
 5. DNS.SB (185.222.222.222,45.11.45.11)
 6. NextDNS (dns.nextdns.io)
 7. 自定义 DNS 服务器
------------------------------" && echo
}

# 显示帮助信息
show_help() {
    echo "用法: $0 [选项] [服务名]"
    echo "选项:"
    echo "  --install [服务名]  快速安装指定的 DNS 服务"
    echo "  --uninstall         卸载 DNS 代理服务"
    echo "  --help              显示此帮助信息"
    echo ""
    echo "可用的服务名:"
    echo "  dnspod, aliyun, cloudflare, google, dnssb, nextdns, custom"
    echo ""
    echo "示例:"
    echo "  $0 --install dnspod    # 快速安装 DNSPod"
    echo "  $0 --uninstall         # 卸载服务"
    echo "  $0                     # 显示菜单进行交互式安装"
}

# 处理命令行参数
case "$1" in
    --install)
        if [ -z "$2" ]; then
            echo "错误：请指定要安装的服务名"
            show_help
            exit 1
        fi
        if [[ -n "${DNS_SERVICES[$2]}" ]]; then
            main
            if [ "$2" == "custom" ]; then
                configure_custom_dns
            fi
            install_service "$2"
            tips
        else
            echo "错误：未知的服务名 '$2'"
            show_help
            exit 1
        fi
        ;;
    --uninstall)
        uninstall
        ;;
    --help)
        show_help
        ;;
    *)
        if [ -n "$1" ]; then
            echo "错误：未知的选项 '$1'"
            show_help
            exit 1
        fi
        show_menu
        read -e -p " 请输入数字 [1-7]：" num
        if [[ -n "${SERVICE_OPTIONS[$num]}" ]]; then
            main
            if [ "${SERVICE_OPTIONS[$num]}" == "custom" ]; then
                configure_custom_dns
            fi
            install_service "${SERVICE_OPTIONS[$num]}"
            tips
        else
            echo "请输入正确的数字 [1-7]"
            exit 1
        fi
        ;;
esac