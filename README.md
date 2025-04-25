# Fast-DoH

突然发现 Linux 下没有一个很方便的快速设置 DoH 的方法，就写了个脚本

目前支持 `DNSPod`、`Aliyun`、`Cloudflare`、`Google`、`DNS.SB`、`NextDNS`、`IQDNS`、`MoeDNS`

如有其他需要可自行修改 `/etc/systemd/system/dnsproxy.service`

## 使用

```
bash <(curl -sSL "https://raw.githubusercontent.com/9bingyin/Fast-DoH/main/doh.sh")
```

## 卸载

```
bash <(curl -sSL "https://raw.githubusercontent.com/9bingyin/Fast-DoH/main/doh.sh") --uninstall
```

## 鸣谢

[dnsproxy](https://github.com/AdguardTeam/dnsproxy)

[changedns.sh](https://github.com/ernisn/changedns.sh)

[DNS.SB 的教程](https://dns.sb/doh/linux)

## Tips

如遇无法使用UDP的环境，可使用`sed -i "1iuse-vc" /etc/resolv.conf`开启TCP解析
