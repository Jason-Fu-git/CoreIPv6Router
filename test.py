from scapy.all import *
from scapy.layers.inet6 import *
from scapy.layers.inet import *
import time

# IN FRAME CONSTRUCTION

pkt = Ether(src="8c:1f:64:69:10:04", dst="8c:1f:64:69:10:57") \
        / IP(src="10.9.47.66",dst="10.6.47.88") / TCP()
sendp(pkt, iface="本地连接* 4")
    

# ether_src = "aa:aa:aa:aa:aa:aa"
# ether_dst = "54:10:69:64:1f:8c"

# ip_src = "fe80::8e1f:64ff:fe69:1001"
# ip_dst = "fe80::8e1f:64ff:fe69:1004"

# payload = Raw(load = "BEGIN " +"ABCDEFG" * 200 + " END")

# pkt = Ether(src=ether_src, dst=ether_dst)/IPv6(src=ip_src, dst=ip_dst, hlim=55)/ICMPv6EchoRequest()/payload
# sendp(pkt, iface="本地连接* 4")

# TEST

# NS from 1004 to router
# ns_pkt2 = Ether(src="8c:1f:64:69:10:04", dst="8c:1f:64:69:10:54")/IPv6(src="fe80::8e1f:64ff:fe69:1004", dst="fe80::8e1f:64ff:fe69:1054", hlim=255)/ICMPv6ND_NA(tgt="fe80::8e1f:64ff:fe69:1004")/ICMPv6NDOptSrcLLAddr(lladdr="8c:1f:64:69:10:04")
# sendp(ns_pkt2, iface="以太网 13")
# time.sleep(1)

# NS from 1001 to router
# ns_pkt = Ether(src="8c:1f:64:69:10:01", dst="8c:1f:64:69:10:54")/IPv6(src="fe80::8e1f:64ff:fe69:1001", dst="fe80::8e1f:64ff:fe69:1054", hlim=255)/ICMPv6ND_NS(tgt="fe80::8e1f:64ff:fe69:1054")/ICMPv6NDOptSrcLLAddr(lladdr="8c:1f:64:69:10:01")
# sendp(ns_pkt, iface="以太网 13")
# time.sleep(1)

# # ipv6 pkt from 1001 to 1004
# ipv6_pkt = Ether(src="8c:1f:64:69:10:01", dst="8c:1f:64:69:10:54")/IPv6(src="fe80::8e1f:64ff:fe69:1001", dst="fe80::8e1f:64ff:fe69:1004", hlim=64)/ICMPv6EchoRequest()/Raw(load="Hello 1004!")
# sendp(ipv6_pkt, iface="以太网 13")
# time.sleep(1)

# ipv6 pkt from 1004 to 1001
# ipv6_pkt2 = Ether(src="8c:1f:64:69:10:04", dst="8c:1f:64:69:10:54")/IPv6(src="fe80::8e1f:64ff:fe69:1004", dst="fe80::8e1f:64ff:fe69:1001", hlim=1)/ICMPv6EchoRequest()/Raw(load="Hello 1001!")
# sendp(ipv6_pkt2, iface="以太网 10")
# time.sleep(1)

