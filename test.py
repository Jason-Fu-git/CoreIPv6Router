from scapy.all import *
from scapy.layers.inet6 import *

ether_src = "aa:aa:aa:aa:aa:aa"
ether_dst = "54:10:69:64:1f:8c"

ip_src = "fe80::8e1f:64ff:fe69:1001"
ip_dst = "fe80::8e1f:64ff:fe69:1004"

payload = Raw(load = "D" * 20 + "C" * 20 + "B" *20 + "A"*20)

pkt = Ether(src=ether_src, dst=ether_dst)/IPv6(src=ip_src, dst=ip_dst, hlim=1)/ICMPv6EchoRequest()/payload
sendp(pkt, iface="本地连接* 11")