from scapy.all import *
from scapy.layers.inet6 import *
from scapy.layers.inet import *
from scapy.layers.rip import *
from scapy.contrib.ripng import *
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

src_address = "fe80::8e1f:64ff:fe69:1001"
src_address_another = "fe80::8e1f:64ff:fe69:1002"
dst_address = "fe80::8e1f:64ff:fe69:1054"
dst_address_another = "fe80::8e1f:64ff:fe69:1055"

src_mac = "8c:1f:64:69:10:01"
src_mac_another = "8c:1f:64:69:10:02"
dst_mac = "8c:1f:64:69:10:54"
dst_mac_another = "8c:1f:64:69:10:55"

ether_packet = Ether(src=src_mac, dst=dst_mac)
ether_packet_another = Ether(src=src_mac_another, dst=dst_mac_another)
ipv6_packet = IPv6(src=src_address, dst=dst_address)
ipv6_packet_another = IPv6(src=src_address_another, dst=dst_address_another)
udp_packet = UDP(sport=521, dport=521)  # RIPng 使用 UDP 端口 521
udp_normal_packet = UDP(sport=30001, dport=30002)


def send_ns(iface=""):
    ns_packet = ICMPv6ND_NS(tgt=dst_address)
    ns_packet_another = ICMPv6ND_NS(tgt=dst_address_another)
    ns_option = ICMPv6NDOptSrcLLAddr(lladdr=src_mac)
    ns_option_another = ICMPv6NDOptSrcLLAddr(lladdr=src_mac_another)
    packet = ether_packet / ipv6_packet / ns_packet / ns_option
    packet_another = ether_packet_another / ipv6_packet_another / ns_packet_another / ns_option_another
    sendp(packet, iface=iface)
    sendp(packet_another, iface=iface)


def send_ripng_request(iface=""):

    ripng_packet = RIP(cmd=1)  # cmd=1 表示 Request 报文
    
    # 添加 RIPng 表项
    ripng_entry1 = RIPngEntry(
        prefix_or_nh="2001:db8::",  # 路由前缀
        routetag=0,              # 路由标签
        prefixlen=64,       # 前缀长度
        metric=1            # 跳数
    )

    ripng_entry2 = RIPngEntry(
        prefix_or_nh="2001:db8:1::",  # 路由前缀
        routetag=0,                # 路由标签
        prefixlen=64,         # 前缀长度
        metric=2              # 跳数
    )

    # 构建完整数据包
    packet = ether_packet / ipv6_packet / udp_packet / ripng_packet / ripng_entry1 / ripng_entry2

    # 发送数据包，iface指定接口名（根据实际接口调整）
    sendp(packet, iface=iface)


def send_ripng_response(iface=""):
    ripng_packet = RIP(cmd=2)
    ripng_entry1 = RIPngEntry(
        prefix_or_nh="2a02:26f7:da80::",
        routetag=0,
        prefixlen=48,
        metric=10
    )
    ripng_entry2 = RIPngEntry(
        prefix_or_nh="2803:3550:109::",
        routetag=0,
        prefixlen=48,
        metric=9
    )
    ripng_entry3 = RIPngEntry(
        prefix_or_nh="2804:43f4:20::",
        routetag=0,
        prefixlen=44,
        metric=8
    )
    ripng_entry4 = RIPngEntry(
        prefix_or_nh="2401:d800:7d40::",
        routetag=0,
        prefixlen=44,
        metric=7
    )
    packet = ether_packet / ipv6_packet / udp_packet / ripng_packet / ripng_entry1 / ripng_entry2
    packet_another = ether_packet_another / ipv6_packet_another / udp_packet / ripng_packet / ripng_entry3 / ripng_entry4
    sendp(packet, iface=iface)
    sendp(packet_another, iface=iface)


def send_udp(iface=""):
    payload = b"114514ACCEED1919810" 
    payload_another = b"1919810HMMHMMHMMAAAAAAAHHHHHHH"
    packet = Ether(src="8c:1f:64:69:10:77", dst=dst_mac) / IPv6(src="fe80::1145", dst="2803:3550:109::1145") / udp_normal_packet / payload
    packet_another = Ether(src="8c:1f:64:69:10:78", dst=dst_mac_another) / IPv6(src="fe80::4514", dst="2401:d800:7d40::1145") / udp_normal_packet / payload_another
    sendp(packet, iface=iface)
    sendp(packet_another, iface=iface)


def send_ripng_response_long(iface=""):
    ripng_packet = RIP(cmd=2)
    packet = ether_packet / ipv6_packet / udp_packet / ripng_packet
    with open("fib_shuffled_0.txt", "r") as f:
        for _ in range(71):
            ip, length, unused_a, unused_b = f.readline().strip().split()
            packet = packet / RIPngEntry(prefix_or_nh=ip, routetag=0, prefixlen=int(length), metric=6)
    sendp(packet, iface=iface)


def send_udp_long(iface="", hop_limit=64):
    payload = b"114514ACCEED1919810/" * 70
    packet = Ether(src="8c:1f:64:69:10:77", dst=dst_mac) / IPv6(src="fe80::1145", dst="2803:3550:109::1145", hlim=hop_limit) / udp_normal_packet / payload
    sendp(packet, iface=iface)


local_iface = "本地连接* 1"

send_ns(iface=local_iface)
send_ripng_response_long(iface=local_iface)
send_udp_long(iface=local_iface)
send_udp_long(iface=local_iface, hop_limit=1)
send_udp_long(iface=local_iface, hop_limit=32)

