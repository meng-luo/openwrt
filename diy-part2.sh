#!/bin/bash
#
# diy-part2.sh — feeds install 之后、make defconfig 之前执行
# 目标上游：immortalwrt/immortalwrt @ openwrt-24.10
#
# 本脚本里每一条 sed 的匹配串都在 immortalwrt 24.10 源码里核实过：
#   package/base-files/files/bin/config_generate:165  lan) ipad=${ipaddr:-"192.168.1.1"} ;;
#   package/base-files/files/bin/config_generate:314  set system.@system[-1].hostname='ImmortalWrt'
#   feeds/luci/collections/luci-light/Makefile        +luci-theme-bootstrap
#
set -e

echo "=========================================================="
echo " diy-part2.sh @ $(pwd)"
echo "=========================================================="

# ---------------------------------------------------------------
# 1) 默认 LAN IP -> 192.168.31.1
# ---------------------------------------------------------------
CG=package/base-files/files/bin/config_generate
[ -f "$CG" ] || { echo "FATAL: 找不到 $CG"; exit 1; }
grep -q '192\.168\.1\.1' "$CG" || { echo "FATAL: config_generate 里没有 192.168.1.1，上游结构变了"; exit 1; }
sed -i 's/192\.168\.1\.1/192.168.31.1/g' "$CG"
echo "[1] LAN IP -> 192.168.31.1  OK"

# ---------------------------------------------------------------
# 2) 默认主机名 -> Mengluo_Router
#    （注意：immortalwrt 用的是 'ImmortalWrt'，不是 'OpenWrt'，
#      所以 lege 时代那句 s/OpenWrt/.../ 在这里是空操作，必须换匹配串）
# ---------------------------------------------------------------
grep -q "hostname='ImmortalWrt'" "$CG" || { echo "FATAL: 主机名匹配串不成立，上游改了"; exit 1; }
sed -i "s/hostname='ImmortalWrt'/hostname='Mengluo_Router'/" "$CG"
echo "[2] hostname -> Mengluo_Router  OK"

# ---------------------------------------------------------------
# 3) 默认主题 bootstrap -> argon
#    luci-light 集合的 LUCI_DEPENDS 里写死了 +luci-theme-bootstrap
# ---------------------------------------------------------------
LIGHT=feeds/luci/collections/luci-light/Makefile
if [ -f "$LIGHT" ]; then
    sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' "$LIGHT"
    echo "[3] 默认主题 -> argon  OK"
else
    echo "[3] 警告: 未找到 $LIGHT，主题保持 bootstrap"
fi

# ---------------------------------------------------------------
# 4) 系统级 sysctl
# ---------------------------------------------------------------
SC=package/base-files/files/etc/sysctl.conf
[ -f "$SC" ] || { echo "FATAL: 找不到 $SC"; exit 1; }
if ! grep -q 'meng-luo tweaks' "$SC"; then
cat >> "$SC" <<'SYSCTLEOF'

#### meng-luo tweaks：扫描 / 高并发 / BT 场景 ####
# --- conntrack：表大小 + 桶数（OpenWrt 默认 buckets=16384 与 max 262144 不匹配，
#     负载因子 16，桶链过长会直接吃掉单核）---
net.netfilter.nf_conntrack_max=262144
net.netfilter.nf_conntrack_buckets=65536
net.netfilter.nf_conntrack_tcp_timeout_established=7440
# 扫描时大量 SYN_SENT / TIME_WAIT 残留，超时压短能显著降低表项数
net.netfilter.nf_conntrack_tcp_timeout_syn_sent=15
net.netfilter.nf_conntrack_tcp_timeout_syn_recv=15
net.netfilter.nf_conntrack_tcp_timeout_time_wait=15
net.netfilter.nf_conntrack_tcp_timeout_fin_wait=15
net.netfilter.nf_conntrack_tcp_timeout_close_wait=15
net.netfilter.nf_conntrack_tcp_timeout_unacknowledged=15
# BT 的 DHT / uTP
net.netfilter.nf_conntrack_udp_timeout=30
net.netfilter.nf_conntrack_udp_timeout_stream=120
net.netfilter.nf_conntrack_generic_timeout=120
# 自动 helper 分配（FTP/SIP 等）关掉：省 CPU，也少一个攻击面
net.netfilter.nf_conntrack_helper=0

# --- TCP ---
net.ipv4.tcp_congestion_control=bbr
net.ipv4.tcp_slow_start_after_idle=0
net.ipv4.tcp_fastopen=3
# 高并发出站（proxy 的 xray/sing-box、扫描）关键三项
net.ipv4.tcp_tw_reuse=1
net.ipv4.tcp_fin_timeout=15
net.ipv4.ip_local_port_range=10240 65535
net.ipv4.tcp_max_syn_backlog=8192
net.core.somaxconn=4096

# --- 套接字缓冲：默认 212992 会把长 RTT 单流卡在 8Mbps 量级 ---
net.core.rmem_max=16777216
net.core.wmem_max=16777216
net.core.rmem_default=262144
net.core.wmem_default=262144
net.ipv4.tcp_rmem=4096 87380 16777216
net.ipv4.tcp_wmem=4096 65536 16777216

# --- 收包队列：高 pps 扫描时减少 softnet drop ---
net.core.netdev_max_backlog=4096

# --- 邻居表：大范围扫描会打爆（默认 128/512/1024）---
net.ipv4.neigh.default.gc_thresh1=1024
net.ipv4.neigh.default.gc_thresh2=4096
net.ipv4.neigh.default.gc_thresh3=8192
net.ipv6.neigh.default.gc_thresh1=1024
net.ipv6.neigh.default.gc_thresh2=4096
net.ipv6.neigh.default.gc_thresh3=8192

# --- 桥接不过 netfilter ---
net.bridge.bridge-nf-call-arptables=0
net.bridge.bridge-nf-call-iptables=0
net.bridge.bridge-nf-call-ip6tables=0
SYSCTLEOF
    echo "[4] sysctl 已追加  OK"
else
    echo "[4] sysctl 已存在，跳过"
fi

# ---------------------------------------------------------------
# 5) 断言：关键包确实被 feeds install 进了源码树
#    （免得两小时后才发现某个包没装上）
# ---------------------------------------------------------------
echo "----------------------------------------------------------"
for p in luci-app-passwall luci-app-sqm sqm-scripts adguardhome luci-app-adguardhome wireguard-tools; do
    hit=$(ls -d package/feeds/*/"$p" 2>/dev/null | head -1)
    if [ -n "$hit" ]; then
        printf "  %-26s -> %s\n" "$p" "$hit"
    else
        printf "  %-26s -> ** 缺失 **\n" "$p"
        MISSING=1
    fi
done
if [ "${MISSING:-0}" = "1" ]; then
    echo "FATAL: 有包没进树，检查 feeds。"
    echo "提示：luci-app-adguardhome 来自 kenzo 源，若 kenzo 不可达则只缺这一个。"
    exit 1
fi
echo "[5] 关键包校验 OK"

# ---------------------------------------------------------------
# 6) files/ 覆盖层
# ---------------------------------------------------------------
if [ -d files ]; then
    echo "[6] files/ 覆盖层:"
    find files -type f | sed 's/^/    /'
else
    echo "[6] 警告: 没有 files/ 覆盖层"
fi

echo "=========================================================="
echo " diy-part2.sh 完成"
echo "=========================================================="
