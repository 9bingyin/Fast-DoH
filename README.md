# Fast-DoH

突然发现 Linux 下没有一个很方便的快速设置 DoH 的方法，就写了个脚本

目前支持 `DNSPod`、`Aliyun`、`Cloudflare`、`Google`、`DNS.SB`

如有其他需要可自行修改 `/etc/systemd/system/dnsproxy.service`

## 使用

`bash <(curl -sSL "https://raw.githubusercontent.com/9bingyin/Fast-DoH/main/doh.sh")`

## 鸣谢

[dnsproxy](https://github.com/AdguardTeam/dnsproxy)

[changedns.sh](https://github.com/ernisn/changedns.sh)

[DNS.SB 的教程](https://dns.sb/guide/doh/linux/)
