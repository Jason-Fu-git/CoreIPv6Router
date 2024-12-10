`ifndef _FRAME_DATAPATH_VH_
`define _FRAME_DATAPATH_VH_

// 'w' means wide.
localparam DATAW_WIDTH = 8 * 56;
localparam ID_WIDTH = 3;

// README: Your code here.

parameter IP6_HDR_TYPE_ICMPv6 = 8'd58;
parameter IP6_HDR_TYPE_UDP = 8'd17;

parameter UDP_PORT_RIP = 16'd521;

parameter ICMPv6_HDR_TYPE_NS = 8'd135;
parameter ICMPv6_HDR_TYPE_NA = 8'd136;
parameter ICMPv6_HDR_TYPE_RS = 8'd133;
parameter ICMPv6_HDR_TYPE_RA = 8'd134;

parameter IP6_HDR_HOP_LIMIT_DEFAULT = 8'd255;

typedef struct packed {
  logic [(DATAW_WIDTH - 8 * 40 - 8 * 14) - 1:0] p;
  logic [127:0] dst;
  logic [127:0] src;
  logic [7:0] hop_limit;
  logic [7:0] next_hdr;
  logic [15:0] payload_len;
  logic [23:0] flow_lo;
  logic [3:0] version;
  logic [3:0] flow_hi;
} ip6_hdr;

typedef struct packed {
  logic [127:0] dst;
  logic [127:0] src;
  logic [7:0]   hop_limit;
  logic [7:0]   next_hdr;
  logic [15:0]  payload_len;
  logic [23:0]  flow_lo;
  logic [3:0]   version;
  logic [3:0]   flow_hi;
} ip6_hdr_clean;

// TODO: Add options field in ICMPv6 header later.
typedef struct packed {
  logic [127:0] target_addr;
  logic [23:0] reserved_lo;
  logic R;
  logic S;
  logic O;
  logic [4:0] reserved_hi;
  logic [15:0] checksum;
  logic [7:0] code;
  logic [7:0] icmpv6_type;
} icmpv6_hdr;  // now without options

typedef struct packed {
  logic [47:0] mac_addr;
  logic [7:0]  len;
  logic [7:0]  option_type;
} icmpv6_option;

typedef struct packed {
  ip6_hdr ip6;
  logic [15:0] ethertype;
  logic [47:0] src;
  logic [47:0] dst;
} ether_hdr;

typedef struct packed {
  ip6_hdr_clean ip6;
  logic [15:0]  ethertype;
  logic [47:0]  src;
  logic [47:0]  dst;
} ether_hdr_clean;

typedef struct packed {
  icmpv6_option option;
  icmpv6_hdr icmpv6;
  ether_hdr_clean ether;
} NS_packet;

typedef struct packed {
  icmpv6_option option;  // 8 bytes
  icmpv6_hdr icmpv6;  // 24 bytes
  ether_hdr_clean ether;  // includes IPv6 header, 54 bytes
} NA_packet;  // 86 bytes

typedef struct packed {
  // Per-frame metadata.
  // **They are only effective at the first beat.**
  logic [ID_WIDTH - 1:0] id;  // The ingress interface.
  logic [ID_WIDTH - 1:0] dest;  // The egress interface.
  logic drop;  // Drop this frame (i.e., this beat and the following beats till the last)?
  logic dont_touch;  // Do not touch this beat!

  // Drop the next frame? It is useful when you need to shrink a frame
  // (e.g., replace an IPv6 packet to an ND solicitation).
  // You can do so by setting both last and drop_next.
  logic drop_next;

  // README: Your code here.
} frame_meta;

typedef struct packed {
  // AXI-Stream signals.
  ether_hdr data;
  logic [DATAW_WIDTH / 8 - 1:0] keep;
  logic last;
  // The IP core will use this "user" signal to indicate errors, so do not modify it!
  logic [DATAW_WIDTH / 8 - 1:0] user;
  logic valid;

  // Handy signals.
  logic is_first;  // Is this the first beat of a frame?

  frame_meta meta;
} frame_beat;

typedef enum logic [2:0] {
  ERR_NONE,
  ERR_FWT_MISS,
  ERR_NC_MISS,
  ERR_HOP_LIMIT,
  ERR_WRONG_TYPE
} fw_error_t;

typedef struct packed {
  frame_beat data;
  fw_error_t error;
  logic      valid;
} fw_frame_beat_t;

typedef struct packed {
  logic [127:0] ip6_addr;
  logic [47:0]  mac_addr;
  logic [1:0]   iface;
} cache_entry;


`define should_handle(b) \
(b.valid && b.is_first && !b.meta.drop && !b.meta.dont_touch)

`define should_handle_following(b) \
(b.valid && !b.is_first && !b.meta.drop && !b.meta.dont_touch)

// README: Your code here. You can define some other constants like EtherType.
localparam ID_CPU = 3'd4;  // The interface ID of CPU is 4.

localparam ETHERTYPE_IP6 = 16'hdd86;

`define ntohs(x) ({x[7:0], x[15:8]})
`define ntohl(x) ({x[7:0], x[15:7], x[23:15], x[31:23]})
`define htons(x) ({x[7:0], x[15:8]})
`define htonl(x) ({x[7:0], x[15:7], x[23:15], x[31:23]})


`endif
