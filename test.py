from scapy.all import *
from scapy.layers.inet6 import *
from scapy.layers.inet import *
from scapy.layers.rip import *
import time

# IN FRAME CONSTRUCTION

# pkt = Ether(src="8c:1f:64:69:10:04", dst="8c:1f:64:69:10:57") \
#         / IP(src="10.9.47.66",dst="10.6.47.88") / TCP()
# sendp(pkt, iface="本地连接* 4")


# ether_src = "aa:aa:aa:aa:aa:aa"
# ether_dst = "54:10:69:64:1f:8c"

# ip_src = "fe80::8e1f:64ff:fe69:1001"
# ip_dst = "fe80::8e1f:64ff:fe69:1004"

# payload = Raw(load = "BEGIN " +"ABCDEFG" * 200 + " END")

# pkt = Ether(src=ether_src, dst=ether_dst)/IPv6(src=ip_src, dst=ip_dst, hlim=55)/ICMPv6EchoRequest()/payload
# sendp(pkt, iface="本地连接* 4")

# TEST

# na_pkt = Ether(src="8c:1f:64:69:11:04", dst="8c:1f:64:69:10:54")/IPv6(src="fe80::8e1f:64ff:fe69:1114", dst="fe80::8e1f:64ff:fe69:1054", hlim=255)/ICMPv6ND_NA(tgt="fe80::8e1f:64ff:fe69:1054")/ICMPv6NDOptDstLLAddr(lladdr="8c:1f:64:69:11:04")
# sendp(na_pkt, iface="以太网 10")

# na_pkt2 = Ether(src="8c:1f:64:69:11:03", dst="8c:1f:64:69:10:54")/IPv6(src="fe80::8e1f:64ff:fe69:1113", dst="fe80::8e1f:64ff:fe69:1054", hlim=255)/ICMPv6ND_NA(tgt="fe80::8e1f:64ff:fe69:1054")/ICMPv6NDOptDstLLAddr(lladdr="8c:1f:64:69:11:03")
# sendp(na_pkt2, iface="以太网 10")

# NS from 1004 to router
# ns_pkt2 = Ether(src="8c:1f:64:69:10:04", dst="8c:1f:64:69:10:54")/IPv6(src="fe80::8e1f:64ff:fe69:1004", dst="fe80::8e1f:64ff:fe69:1054", hlim=255)/ICMPv6ND_NS(tgt="fe80::8e1f:64ff:fe69:1054")/ICMPv6NDOptSrcLLAddr(lladdr="8c:1f:64:69:10:04")
# sendp(ns_pkt2, iface="以太网 10")

# NS from 1001 to router
# ns_pkt = Ether(src="8c:1f:64:69:10:01", dst="8c:1f:64:69:10:57")/IPv6(src="fe80::8e1f:64ff:fe69:1001", dst="fe80::8e1f:64ff:fe69:1057", hlim=255)/ICMPv6ND_NS(tgt="fe80::8e1f:64ff:fe69:1057")/ICMPv6NDOptSrcLLAddr(lladdr="8c:1f:64:69:10:01")
# sendp(ns_pkt, iface="以太网 10")

# # ipv6 pkt from 1001 to 1004
# ipv6_pkt = Ether(src="8c:1f:64:69:10:01", dst="8c:1f:64:69:10:54")/IPv6(src="fe80::8e1f:64ff:fe69:1001", dst="fe80::8e1f:64ff:fe69:1004", hlim=64)/ICMPv6EchoRequest()/Raw(load="Hello 1004!")
# sendp(ipv6_pkt, iface="以太网 10")

# # ipv6 pkt from 1004 to 1001
# ipv6_pkt2 = Ether(src="8c:1f:64:69:10:04", dst="8c:1f:64:69:10:54")/IPv6(src="fe80::8e1f:64ff:fe69:1004", dst="fe80::8e1f:64ff:fe69:1001", hlim=64)/ICMPv6EchoRequest()/Raw(load="Hello 1001!")
# sendp(ipv6_pkt2, iface="以太网 10")

# # A very long pkt from 1001 to 1004
# ipv6_pkt3 = Ether(src="8c:1f:64:69:10:01", dst="8c:1f:64:69:10:54")/IPv6(src="fe80::8e1f:64ff:fe69:1001", dst="fe80::8e1f:64ff:fe69:1004", hlim=64)/ICMPv6EchoRequest()/Raw(load="S" + "A"*1000 + "E")
# sendp(ipv6_pkt3, iface="以太网 10")

# # invalid hop limit
# ipv6_pkt4 = Ether(src="8c:1f:64:69:10:01", dst="8c:1f:64:69:10:54")/IPv6(src="fe80::8e1f:64ff:fe69:1001", dst="fe80::8e1f:64ff:fe69:1004", hlim=1)/ICMPv6EchoRequest()/Raw(load="S" + "A"*1000 + "E")
# sendp(ipv6_pkt4, iface="以太网 10")

# # invalid dst
# ipv6_pkt5 = Ether(src="8c:1f:64:69:10:01", dst="8c:1f:64:69:10:54")/IPv6(src="fe80::8e1f:64ff:fe69:1001", dst="fe80::8e1f:64ff:fe69:1111", hlim=64)/ICMPv6EchoRequest()
# sendp(ipv6_pkt5, iface="以太网 10")

# # a valid pkt
# ipv6_pkt6 = Ether(src="8c:1f:64:69:10:01", dst="8c:1f:64:69:10:54")/IPv6(src="fe80::8e1f:64ff:fe69:1001", dst="fe80::8e1f:64ff:fe69:1004", hlim=64)/ICMPv6EchoRequest()

# # some ipv4 pkt
# ipv4_pkt =  Ether(src="8c:1f:64:69:10:04", dst="8c:1f:64:69:10:57") \
#         / IP(src="10.9.47.66",dst="10.6.47.88") / TCP()
# sendp(ipv4_pkt, iface="以太网 10")
# sendp(ipv4_pkt, iface="以太网 10")
# sendp(ipv4_pkt, iface="以太网 10")

def send_ripng_request():
    # 源地址和目的地址
    src_address = "fe80::8e1f:64ff:fe69:1001"
    dst_address = "fe80::8e1f:64ff:fe69:1054"

    # 创建RIPng请求包
    ether_packet = Ether(src="8c:1f:64:69:10:01", dst="8c:1f:64:69:10:54")
    ipv6_packet = IPv6(src=src_address, dst=dst_address)
    udp_packet = UDP(sport=521, dport=521)  # RIPng 使用 UDP 端口 521
    ripng_packet = RIP(cmd=1)  # cmd=1 表示 Request 报文

    # 构建完整数据包
    packet = ether_packet / ipv6_packet / udp_packet / ripng_packet

    # 发送数据包，iface指定接口名（根据实际接口调整）
    sendp(packet, iface="本地连接* 12")


send_ripng_request()
