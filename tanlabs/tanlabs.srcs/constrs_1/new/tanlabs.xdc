# Clocks
set_property -dict {PACKAGE_PIN AH10 IOSTANDARD LVDS} [get_ports sysclk_100_n] ;# SYSCLK_N
set_property -dict {PACKAGE_PIN AG10 IOSTANDARD LVDS} [get_ports sysclk_100_p] ;# SYSCLK_P 100MHz
set_property -dict {PACKAGE_PIN T26 IOSTANDARD LVCMOS33} [get_ports clk_50M] ;# CLK_IN0 50MHz main clock input
set_property -dict {PACKAGE_PIN U27 IOSTANDARD LVCMOS33} [get_ports clk_11M0592] ;# CLK_IN1 11.0592MHz clock for UART

create_clock -period 10.000 -name sysclk_100 -waveform {0.000 5.000} [get_ports sysclk_100_p]
create_clock -period 20.000 -name clk_50M -waveform {0.000 10.000} [get_ports clk_50M]
create_clock -period 90.422 -name clk_11M0592 -waveform {0.000 45.211} [get_ports clk_11M0592]

# GT clocks 125MHz, 156.25MHz
set_property PACKAGE_PIN R8 [get_ports gtclk_125_p]
set_property PACKAGE_PIN R7 [get_ports gtclk_125_n]
set_property PACKAGE_PIN U7 [get_ports gtclk_15625_n] ;# MGT_CLK1_N
set_property PACKAGE_PIN U8 [get_ports gtclk_15625_p] ;# MGT_CLK1_P

create_clock -period 8.000 -name gtclk_125 -waveform {0.000 4.000} [get_ports gtclk_125_p]
create_clock -period 6.400 -name gtclk_15625 -waveform {0.000 3.200} [get_ports gtclk_15625_p]

# Reset Button (BTN6)
set_property -dict {PACKAGE_PIN U30 IOSTANDARD LVCMOS33} [get_ports RST]
set_false_path -from [get_ports RST]

# Clock Button (BTN5)
set_property -dict {PACKAGE_PIN V30 IOSTANDARD LVCMOS33} [get_ports BTN]
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets BTN_IBUF]

# Buttons
set_property -dict {PACKAGE_PIN W26 IOSTANDARD LVCMOS33} [get_ports {touch_btn[0]}]
set_property -dict {PACKAGE_PIN W27 IOSTANDARD LVCMOS33} [get_ports {touch_btn[1]}]
set_property -dict {PACKAGE_PIN W29 IOSTANDARD LVCMOS33} [get_ports {touch_btn[2]}]
set_property -dict {PACKAGE_PIN V29 IOSTANDARD LVCMOS33} [get_ports {touch_btn[3]}]

# GPIOs
set_property -dict {PACKAGE_PIN AJ21 IOSTANDARD LVCMOS33} [get_ports ext_io[0]] ;# EXIO0
set_property -dict {PACKAGE_PIN AK21 IOSTANDARD LVCMOS33} [get_ports ext_io[1]] ;# EXIO1
set_property -dict {PACKAGE_PIN AJ22 IOSTANDARD LVCMOS33} [get_ports ext_io[2]] ;# EXIO2
set_property -dict {PACKAGE_PIN AJ23 IOSTANDARD LVCMOS33} [get_ports ext_io[3]] ;# EXIO3
set_property -dict {PACKAGE_PIN AK23 IOSTANDARD LVCMOS33} [get_ports ext_io[4]] ;# EXIO4
set_property -dict {PACKAGE_PIN AH20 IOSTANDARD LVCMOS33} [get_ports ext_io[5]] ;# EXIO5
set_property -dict {PACKAGE_PIN AH21 IOSTANDARD LVCMOS33} [get_ports ext_io[6]] ;# EXIO6
set_property -dict {PACKAGE_PIN AK20 IOSTANDARD LVCMOS33} [get_ports ext_io[7]] ;# EXIO7

# HDMI
set_property -dict {PACKAGE_PIN M28 IOSTANDARD LVCMOS33} [get_ports hdmi_ddc_scl] ;# HDMI_DDC_SCL
set_property -dict {PACKAGE_PIN M27 IOSTANDARD LVCMOS33} [get_ports hdmi_ddc_sda] ;# HDMI_DDC_SDA
set_property -dict {PACKAGE_PIN N27 IOSTANDARD LVCMOS33} [get_ports hdmi_hotplug] ;# HDMI_HOTPLUG
set_property -dict {PACKAGE_PIN L27 IOSTANDARD TMDS_33} [get_ports hdmi_data_n[0]] ;# HDMI_TMDS0_N
set_property -dict {PACKAGE_PIN L26 IOSTANDARD TMDS_33} [get_ports hdmi_data_p[0]] ;# HDMI_TMDS0_P
set_property -dict {PACKAGE_PIN K29 IOSTANDARD TMDS_33} [get_ports hdmi_data_n[1]] ;# HDMI_TMDS1_N
set_property -dict {PACKAGE_PIN K28 IOSTANDARD TMDS_33} [get_ports hdmi_data_p[1]] ;# HDMI_TMDS1_P
set_property -dict {PACKAGE_PIN J28 IOSTANDARD TMDS_33} [get_ports hdmi_data_n[2]] ;# HDMI_TMDS2_N
set_property -dict {PACKAGE_PIN J27 IOSTANDARD TMDS_33} [get_ports hdmi_data_p[2]] ;# HDMI_TMDS2_P
set_property -dict {PACKAGE_PIN M30 IOSTANDARD TMDS_33} [get_ports hdmi_clock_n] ;# HDMI_TMDSC_N
set_property -dict {PACKAGE_PIN M29 IOSTANDARD TMDS_33} [get_ports hdmi_clock_p] ;# HDMI_TMDSC_P

# LEDs
set_property -dict {PACKAGE_PIN C15 IOSTANDARD LVCMOS33} [get_ports {led[0]}]
set_property -dict {PACKAGE_PIN B14 IOSTANDARD LVCMOS33} [get_ports {led[1]}]
set_property -dict {PACKAGE_PIN A13 IOSTANDARD LVCMOS33} [get_ports {led[2]}]
set_property -dict {PACKAGE_PIN C14 IOSTANDARD LVCMOS33} [get_ports {led[3]}]
set_property -dict {PACKAGE_PIN B13 IOSTANDARD LVCMOS33} [get_ports {led[4]}]
set_property -dict {PACKAGE_PIN A12 IOSTANDARD LVCMOS33} [get_ports {led[5]}]
set_property -dict {PACKAGE_PIN B12 IOSTANDARD LVCMOS33} [get_ports {led[6]}]
set_property -dict {PACKAGE_PIN A11 IOSTANDARD LVCMOS33} [get_ports {led[7]}]
set_property -dict {PACKAGE_PIN A18 IOSTANDARD LVCMOS33} [get_ports {led[8]}]
set_property -dict {PACKAGE_PIN B18 IOSTANDARD LVCMOS33} [get_ports {led[9]}]
set_property -dict {PACKAGE_PIN B17 IOSTANDARD LVCMOS33} [get_ports {led[10]}]
set_property -dict {PACKAGE_PIN A17 IOSTANDARD LVCMOS33} [get_ports {led[11]}]
set_property -dict {PACKAGE_PIN A16 IOSTANDARD LVCMOS33} [get_ports {led[12]}]
set_property -dict {PACKAGE_PIN C16 IOSTANDARD LVCMOS33} [get_ports {led[13]}]
set_property -dict {PACKAGE_PIN A15 IOSTANDARD LVCMOS33} [get_ports {led[14]}]
set_property -dict {PACKAGE_PIN B15 IOSTANDARD LVCMOS33} [get_ports {led[15]}]

# DPY0
set_property -dict {PACKAGE_PIN H19 IOSTANDARD LVCMOS33} [get_ports dpy0[0]] ;# LED16
set_property -dict {PACKAGE_PIN G19 IOSTANDARD LVCMOS33} [get_ports dpy0[1]] ;# LED17
set_property -dict {PACKAGE_PIN E18 IOSTANDARD LVCMOS33} [get_ports dpy0[2]] ;# LED18
set_property -dict {PACKAGE_PIN D18 IOSTANDARD LVCMOS33} [get_ports dpy0[3]] ;# LED19
set_property -dict {PACKAGE_PIN J17 IOSTANDARD LVCMOS33} [get_ports dpy0[4]] ;# LED20
set_property -dict {PACKAGE_PIN L18 IOSTANDARD LVCMOS33} [get_ports dpy0[5]] ;# LED21
set_property -dict {PACKAGE_PIN L17 IOSTANDARD LVCMOS33} [get_ports dpy0[6]] ;# LED22
set_property -dict {PACKAGE_PIN L13 IOSTANDARD LVCMOS33} [get_ports dpy0[7]] ;# LED23

# DPY1
set_property -dict {PACKAGE_PIN F13 IOSTANDARD LVCMOS33} [get_ports dpy1[0]] ;# LED24
set_property -dict {PACKAGE_PIN G13 IOSTANDARD LVCMOS33} [get_ports dpy1[1]] ;# LED25
set_property -dict {PACKAGE_PIN G12 IOSTANDARD LVCMOS33} [get_ports dpy1[2]] ;# LED26
set_property -dict {PACKAGE_PIN H12 IOSTANDARD LVCMOS33} [get_ports dpy1[3]] ;# LED27
set_property -dict {PACKAGE_PIN G15 IOSTANDARD LVCMOS33} [get_ports dpy1[4]] ;# LED28
set_property -dict {PACKAGE_PIN H15 IOSTANDARD LVCMOS33} [get_ports dpy1[5]] ;# LED29
set_property -dict {PACKAGE_PIN G14 IOSTANDARD LVCMOS33} [get_ports dpy1[6]] ;# LED30
set_property -dict {PACKAGE_PIN H14 IOSTANDARD LVCMOS33} [get_ports dpy1[7]] ;# LED31

# DIP Switch
set_property -dict {PACKAGE_PIN AK25 IOSTANDARD LVCMOS33} [get_ports {dip_sw[0]}]
set_property -dict {PACKAGE_PIN AK26 IOSTANDARD LVCMOS33} [get_ports {dip_sw[1]}]
set_property -dict {PACKAGE_PIN AJ26 IOSTANDARD LVCMOS33} [get_ports {dip_sw[2]}]
set_property -dict {PACKAGE_PIN AJ27 IOSTANDARD LVCMOS33} [get_ports {dip_sw[3]}]
set_property -dict {PACKAGE_PIN AK28 IOSTANDARD LVCMOS33} [get_ports {dip_sw[4]}]
set_property -dict {PACKAGE_PIN AJ28 IOSTANDARD LVCMOS33} [get_ports {dip_sw[5]}]
set_property -dict {PACKAGE_PIN AK29 IOSTANDARD LVCMOS33} [get_ports {dip_sw[6]}]
set_property -dict {PACKAGE_PIN AK30 IOSTANDARD LVCMOS33} [get_ports {dip_sw[7]}]
set_property -dict {PACKAGE_PIN AF23 IOSTANDARD LVCMOS33} [get_ports {dip_sw[8]}]
set_property -dict {PACKAGE_PIN AG23 IOSTANDARD LVCMOS33} [get_ports {dip_sw[9]}]
set_property -dict {PACKAGE_PIN AD23 IOSTANDARD LVCMOS33} [get_ports {dip_sw[10]}]
set_property -dict {PACKAGE_PIN AE23 IOSTANDARD LVCMOS33} [get_ports {dip_sw[11]}]
set_property -dict {PACKAGE_PIN AB22 IOSTANDARD LVCMOS33} [get_ports {dip_sw[12]}]
set_property -dict {PACKAGE_PIN AC22 IOSTANDARD LVCMOS33} [get_ports {dip_sw[13]}]
set_property -dict {PACKAGE_PIN AF22 IOSTANDARD LVCMOS33} [get_ports {dip_sw[14]}]
set_property -dict {PACKAGE_PIN AH22 IOSTANDARD LVCMOS33} [get_ports {dip_sw[15]}]

# BaseRAM
set_property -dict {PACKAGE_PIN AB27 IOSTANDARD LVCMOS33} [get_ports base_ram_addr[0]] ;# BASE_RAM_A0
set_property -dict {PACKAGE_PIN AC27 IOSTANDARD LVCMOS33} [get_ports base_ram_addr[1]] ;# BASE_RAM_A1
set_property -dict {PACKAGE_PIN AC26 IOSTANDARD LVCMOS33} [get_ports base_ram_addr[2]] ;# BASE_RAM_A2
set_property -dict {PACKAGE_PIN AD28 IOSTANDARD LVCMOS33} [get_ports base_ram_addr[3]] ;# BASE_RAM_A3
set_property -dict {PACKAGE_PIN AD27 IOSTANDARD LVCMOS33} [get_ports base_ram_addr[4]] ;# BASE_RAM_A4
set_property -dict {PACKAGE_PIN A20 IOSTANDARD LVCMOS33} [get_ports base_ram_addr[5]] ;# BASE_RAM_A5
set_property -dict {PACKAGE_PIN B20 IOSTANDARD LVCMOS33} [get_ports base_ram_addr[6]] ;# BASE_RAM_A6
set_property -dict {PACKAGE_PIN C20 IOSTANDARD LVCMOS33} [get_ports base_ram_addr[7]] ;# BASE_RAM_A7
set_property -dict {PACKAGE_PIN A21 IOSTANDARD LVCMOS33} [get_ports base_ram_addr[8]] ;# BASE_RAM_A8
set_property -dict {PACKAGE_PIN AF27 IOSTANDARD LVCMOS33} [get_ports base_ram_addr[9]] ;# BASE_RAM_A9
set_property -dict {PACKAGE_PIN AF28 IOSTANDARD LVCMOS33} [get_ports base_ram_addr[10]] ;# BASE_RAM_A10
set_property -dict {PACKAGE_PIN AG27 IOSTANDARD LVCMOS33} [get_ports base_ram_addr[11]] ;# BASE_RAM_A11
set_property -dict {PACKAGE_PIN AG28 IOSTANDARD LVCMOS33} [get_ports base_ram_addr[12]] ;# BASE_RAM_A12
set_property -dict {PACKAGE_PIN AH26 IOSTANDARD LVCMOS33} [get_ports base_ram_addr[13]] ;# BASE_RAM_A13
set_property -dict {PACKAGE_PIN AH27 IOSTANDARD LVCMOS33} [get_ports base_ram_addr[14]] ;# BASE_RAM_A14
set_property -dict {PACKAGE_PIN AJ29 IOSTANDARD LVCMOS33} [get_ports base_ram_addr[15]] ;# BASE_RAM_A15
set_property -dict {PACKAGE_PIN AH30 IOSTANDARD LVCMOS33} [get_ports base_ram_addr[16]] ;# BASE_RAM_A16
set_property -dict {PACKAGE_PIN AH29 IOSTANDARD LVCMOS33} [get_ports base_ram_addr[17]] ;# BASE_RAM_A17
set_property -dict {PACKAGE_PIN AG30 IOSTANDARD LVCMOS33} [get_ports base_ram_addr[18]] ;# BASE_RAM_A18
set_property -dict {PACKAGE_PIN AF30 IOSTANDARD LVCMOS33} [get_ports base_ram_addr[19]] ;# BASE_RAM_A19
set_property -dict {PACKAGE_PIN AE28 IOSTANDARD LVCMOS33} [get_ports base_ram_addr[20]] ;# BASE_RAM_A20
set_property -dict {PACKAGE_PIN AD26 IOSTANDARD LVCMOS33} [get_ports base_ram_be_n[0]] ;# BASE_RAM_BE0
set_property -dict {PACKAGE_PIN AD24 IOSTANDARD LVCMOS33} [get_ports base_ram_be_n[1]] ;# BASE_RAM_BE1
set_property -dict {PACKAGE_PIN B19 IOSTANDARD LVCMOS33} [get_ports base_ram_be_n[2]] ;# BASE_RAM_BE2
set_property -dict {PACKAGE_PIN C19 IOSTANDARD LVCMOS33} [get_ports base_ram_be_n[3]] ;# BASE_RAM_BE3
set_property -dict {PACKAGE_PIN AE26 IOSTANDARD LVCMOS33} [get_ports base_ram_ce_n] ;# BASE_RAM_CE
set_property -dict {PACKAGE_PIN Y24 IOSTANDARD LVCMOS33} [get_ports base_ram_data[0]] ;# BASE_RAM_D0
set_property -dict {PACKAGE_PIN Y25 IOSTANDARD LVCMOS33} [get_ports base_ram_data[1]] ;# BASE_RAM_D1
set_property -dict {PACKAGE_PIN AA25 IOSTANDARD LVCMOS33} [get_ports base_ram_data[2]] ;# BASE_RAM_D2
set_property -dict {PACKAGE_PIN AA26 IOSTANDARD LVCMOS33} [get_ports base_ram_data[3]] ;# BASE_RAM_D3
set_property -dict {PACKAGE_PIN AB24 IOSTANDARD LVCMOS33} [get_ports base_ram_data[4]] ;# BASE_RAM_D4
set_property -dict {PACKAGE_PIN AB25 IOSTANDARD LVCMOS33} [get_ports base_ram_data[5]] ;# BASE_RAM_D5
set_property -dict {PACKAGE_PIN AC24 IOSTANDARD LVCMOS33} [get_ports base_ram_data[6]] ;# BASE_RAM_D6
set_property -dict {PACKAGE_PIN AC25 IOSTANDARD LVCMOS33} [get_ports base_ram_data[7]] ;# BASE_RAM_D7
set_property -dict {PACKAGE_PIN AH25 IOSTANDARD LVCMOS33} [get_ports base_ram_data[8]] ;# BASE_RAM_D8
set_property -dict {PACKAGE_PIN AH24 IOSTANDARD LVCMOS33} [get_ports base_ram_data[9]] ;# BASE_RAM_D9
set_property -dict {PACKAGE_PIN AG25 IOSTANDARD LVCMOS33} [get_ports base_ram_data[10]] ;# BASE_RAM_D10
set_property -dict {PACKAGE_PIN AG24 IOSTANDARD LVCMOS33} [get_ports base_ram_data[11]] ;# BASE_RAM_D11
set_property -dict {PACKAGE_PIN AF26 IOSTANDARD LVCMOS33} [get_ports base_ram_data[12]] ;# BASE_RAM_D12
set_property -dict {PACKAGE_PIN AF25 IOSTANDARD LVCMOS33} [get_ports base_ram_data[13]] ;# BASE_RAM_D13
set_property -dict {PACKAGE_PIN AE25 IOSTANDARD LVCMOS33} [get_ports base_ram_data[14]] ;# BASE_RAM_D14
set_property -dict {PACKAGE_PIN AE24 IOSTANDARD LVCMOS33} [get_ports base_ram_data[15]] ;# BASE_RAM_D15
set_property -dict {PACKAGE_PIN Y30 IOSTANDARD LVCMOS33} [get_ports base_ram_data[16]] ;# BASE_RAM_D16
set_property -dict {PACKAGE_PIN Y29 IOSTANDARD LVCMOS33} [get_ports base_ram_data[17]] ;# BASE_RAM_D17
set_property -dict {PACKAGE_PIN AA30 IOSTANDARD LVCMOS33} [get_ports base_ram_data[18]] ;# BASE_RAM_D18
set_property -dict {PACKAGE_PIN AB30 IOSTANDARD LVCMOS33} [get_ports base_ram_data[19]] ;# BASE_RAM_D19
set_property -dict {PACKAGE_PIN AC29 IOSTANDARD LVCMOS33} [get_ports base_ram_data[20]] ;# BASE_RAM_D20
set_property -dict {PACKAGE_PIN AC30 IOSTANDARD LVCMOS33} [get_ports base_ram_data[21]] ;# BASE_RAM_D21
set_property -dict {PACKAGE_PIN AD29 IOSTANDARD LVCMOS33} [get_ports base_ram_data[22]] ;# BASE_RAM_D22
set_property -dict {PACKAGE_PIN AE30 IOSTANDARD LVCMOS33} [get_ports base_ram_data[23]] ;# BASE_RAM_D23
set_property -dict {PACKAGE_PIN E26 IOSTANDARD LVCMOS33} [get_ports base_ram_data[24]] ;# BASE_RAM_D24
set_property -dict {PACKAGE_PIN F26 IOSTANDARD LVCMOS33} [get_ports base_ram_data[25]] ;# BASE_RAM_D25
set_property -dict {PACKAGE_PIN C27 IOSTANDARD LVCMOS33} [get_ports base_ram_data[26]] ;# BASE_RAM_D26
set_property -dict {PACKAGE_PIN D27 IOSTANDARD LVCMOS33} [get_ports base_ram_data[27]] ;# BASE_RAM_D27
set_property -dict {PACKAGE_PIN C21 IOSTANDARD LVCMOS33} [get_ports base_ram_data[28]] ;# BASE_RAM_D28
set_property -dict {PACKAGE_PIN D21 IOSTANDARD LVCMOS33} [get_ports base_ram_data[29]] ;# BASE_RAM_D29
set_property -dict {PACKAGE_PIN C22 IOSTANDARD LVCMOS33} [get_ports base_ram_data[30]] ;# BASE_RAM_D30
set_property -dict {PACKAGE_PIN D22 IOSTANDARD LVCMOS33} [get_ports base_ram_data[31]] ;# BASE_RAM_D31
set_property -dict {PACKAGE_PIN A22 IOSTANDARD LVCMOS33} [get_ports base_ram_oe_n] ;# BASE_RAM_OE
set_property -dict {PACKAGE_PIN AE29 IOSTANDARD LVCMOS33} [get_ports base_ram_we_n] ;# BASE_RAM_WE

# RGMII
set_property -dict {PACKAGE_PIN E21 IOSTANDARD LVCMOS33} [get_ports rgmii_mdc] ;# RGMII_MDC
set_property -dict {PACKAGE_PIN F21 IOSTANDARD LVCMOS33} [get_ports rgmii_mdio] ;# RGMII_MDIO
set_property -dict {PACKAGE_PIN D26 IOSTANDARD LVCMOS33} [get_ports rgmii_rxclk] ;# RGMII_RXCLK
set_property -dict {PACKAGE_PIN E28 IOSTANDARD LVCMOS33} [get_ports rgmii_rxctl] ;# RGMII_RXCTL
set_property -dict {PACKAGE_PIN F28 IOSTANDARD LVCMOS33} [get_ports rgmii_rxd[0]] ;# RGMII_RXD0
set_property -dict {PACKAGE_PIN G28 IOSTANDARD LVCMOS33} [get_ports rgmii_rxd[1]] ;# RGMII_RXD1
set_property -dict {PACKAGE_PIN G27 IOSTANDARD LVCMOS33} [get_ports rgmii_rxd[2]] ;# RGMII_RXD2
set_property -dict {PACKAGE_PIN H27 IOSTANDARD LVCMOS33} [get_ports rgmii_rxd[3]] ;# RGMII_RXD3
set_property -dict {PACKAGE_PIN C25 IOSTANDARD LVCMOS33} [get_ports rgmii_txclk] ;# RGMII_TXCLK
set_property -dict {PACKAGE_PIN G23 IOSTANDARD LVCMOS33} [get_ports rgmii_txctl] ;# RGMII_TXCTL
set_property -dict {PACKAGE_PIN G24 IOSTANDARD LVCMOS33} [get_ports rgmii_txd[0]] ;# RGMII_TXD0
set_property -dict {PACKAGE_PIN H24 IOSTANDARD LVCMOS33} [get_ports rgmii_txd[1]] ;# RGMII_TXD1
set_property -dict {PACKAGE_PIN E23 IOSTANDARD LVCMOS33} [get_ports rgmii_txd[2]] ;# RGMII_TXD2
set_property -dict {PACKAGE_PIN F23 IOSTANDARD LVCMOS33} [get_ports rgmii_txd[3]] ;# RGMII_TXD3

# SD Card
set_property -dict {PACKAGE_PIN E13 IOSTANDARD LVCMOS33} [get_ports sdcard_clk] ;# TF_CLK
set_property -dict {PACKAGE_PIN D13 IOSTANDARD LVCMOS33} [get_ports sdcard_cmd] ;# TF_CMD
set_property -dict {PACKAGE_PIN C12 IOSTANDARD LVCMOS33} [get_ports sdcard_data[0]] ;# TF_D0
set_property -dict {PACKAGE_PIN D12 IOSTANDARD LVCMOS33} [get_ports sdcard_data[1]] ;# TF_D1
set_property -dict {PACKAGE_PIN D14 IOSTANDARD LVCMOS33} [get_ports sdcard_data[2]] ;# TF_D2
set_property -dict {PACKAGE_PIN E14 IOSTANDARD LVCMOS33} [get_ports sdcard_data[3]] ;# TF_D3
set_property -dict {PACKAGE_PIN F12 IOSTANDARD LVCMOS33} [get_ports sdcard_cd] ;# TF_DET

# USB
set_property -dict {PACKAGE_PIN J23 IOSTANDARD LVCMOS33} [get_ports usb_clk] ;# USB_CLK
set_property -dict {PACKAGE_PIN G22 IOSTANDARD LVCMOS33} [get_ports usb_data[0]] ;# USB_D0
set_property -dict {PACKAGE_PIN H22 IOSTANDARD LVCMOS33} [get_ports usb_data[1]] ;# USB_D1
set_property -dict {PACKAGE_PIN H21 IOSTANDARD LVCMOS33} [get_ports usb_data[2]] ;# USB_D2
set_property -dict {PACKAGE_PIN J21 IOSTANDARD LVCMOS33} [get_ports usb_data[3]] ;# USB_D3
set_property -dict {PACKAGE_PIN G20 IOSTANDARD LVCMOS33} [get_ports usb_data[4]] ;# USB_D4
set_property -dict {PACKAGE_PIN K19 IOSTANDARD LVCMOS33} [get_ports usb_data[5]] ;# USB_D5
set_property -dict {PACKAGE_PIN J19 IOSTANDARD LVCMOS33} [get_ports usb_data[6]] ;# USB_D6
set_property -dict {PACKAGE_PIN H20 IOSTANDARD LVCMOS33} [get_ports usb_data[7]] ;# USB_D7
set_property -dict {PACKAGE_PIN K24 IOSTANDARD LVCMOS33} [get_ports usb_dir] ;# USB_DIR
set_property -dict {PACKAGE_PIN K23 IOSTANDARD LVCMOS33} [get_ports usb_nxt] ;# USB_NXT
set_property -dict {PACKAGE_PIN C24 IOSTANDARD LVCMOS33} [get_ports usb_reset] ;# USB_RESET
set_property -dict {PACKAGE_PIN J24 IOSTANDARD LVCMOS33} [get_ports usb_stp] ;# USB_STP

# Zynq HSIO
set_property -dict {PACKAGE_PIN D19 IOSTANDARD TMDS_33} [get_ports zynq_hsio_n[0]] ;# HS0_N
set_property -dict {PACKAGE_PIN E19 IOSTANDARD TMDS_33} [get_ports zynq_hsio_p[0]] ;# HS0_P
set_property -dict {PACKAGE_PIN E20 IOSTANDARD TMDS_33} [get_ports zynq_hsio_n[1]] ;# HS1_N
set_property -dict {PACKAGE_PIN F20 IOSTANDARD TMDS_33} [get_ports zynq_hsio_p[1]] ;# HS1_P
set_property -dict {PACKAGE_PIN F17 IOSTANDARD TMDS_33} [get_ports zynq_hsio_n[2]] ;# HS2_N
set_property -dict {PACKAGE_PIN G17 IOSTANDARD TMDS_33} [get_ports zynq_hsio_p[2]] ;# HS2_P
set_property -dict {PACKAGE_PIN F18 IOSTANDARD TMDS_33} [get_ports zynq_hsio_n[3]] ;# HS3_N
set_property -dict {PACKAGE_PIN G18 IOSTANDARD TMDS_33} [get_ports zynq_hsio_p[3]] ;# HS3_P
set_property -dict {PACKAGE_PIN J18 IOSTANDARD TMDS_33} [get_ports zynq_hsio_n[4]] ;# HS4_N
set_property -dict {PACKAGE_PIN K18 IOSTANDARD TMDS_33} [get_ports zynq_hsio_p[4]] ;# HS4_P

# Zynq LSIO
set_property -dict {PACKAGE_PIN L16 IOSTANDARD LVCMOS33} [get_ports zynq_lsio[0]] ;# LSIO0
set_property -dict {PACKAGE_PIN H16 IOSTANDARD LVCMOS33} [get_ports zynq_lsio[1]] ;# LSIO1
set_property -dict {PACKAGE_PIN H17 IOSTANDARD LVCMOS33} [get_ports zynq_lsio[2]] ;# LSIO2
set_property -dict {PACKAGE_PIN K16 IOSTANDARD LVCMOS33} [get_ports zynq_lsio[3]] ;# LSIO3
set_property -dict {PACKAGE_PIN D16 IOSTANDARD LVCMOS33} [get_ports zynq_lsio[4]] ;# LSIO4
set_property -dict {PACKAGE_PIN C17 IOSTANDARD LVCMOS33} [get_ports zynq_lsio[5]] ;# LSIO5
set_property -dict {PACKAGE_PIN F16 IOSTANDARD LVCMOS33} [get_ports zynq_lsio[6]] ;# LSIO6
set_property -dict {PACKAGE_PIN D17 IOSTANDARD LVCMOS33} [get_ports zynq_lsio[7]] ;# LSIO7
set_property -dict {PACKAGE_PIN J16 IOSTANDARD LVCMOS33} [get_ports uart_tx]
set_property -dict {PACKAGE_PIN E16 IOSTANDARD LVCMOS33} [get_ports uart_rx]
set_property PULLUP true [get_ports uart_rx]

# SODIMM
set_property PACKAGE_PIN AK10 [get_ports {ddr3_addr[0]}]
set_property PACKAGE_PIN AB10 [get_ports {ddr3_addr[1]}]
set_property PACKAGE_PIN AA11 [get_ports {ddr3_addr[2]}]
set_property PACKAGE_PIN AC10 [get_ports {ddr3_addr[3]}]
set_property PACKAGE_PIN Y11 [get_ports {ddr3_addr[4]}]
set_property PACKAGE_PIN AC9 [get_ports {ddr3_addr[5]}]
set_property PACKAGE_PIN AK9 [get_ports {ddr3_addr[6]}]
set_property PACKAGE_PIN AH9 [get_ports {ddr3_addr[7]}]
set_property PACKAGE_PIN AD9 [get_ports {ddr3_addr[8]}]
set_property PACKAGE_PIN AA10 [get_ports {ddr3_addr[9]}]
set_property PACKAGE_PIN AF10 [get_ports {ddr3_addr[10]}]
set_property PACKAGE_PIN AE9 [get_ports {ddr3_addr[11]}]
set_property PACKAGE_PIN Y10 [get_ports {ddr3_addr[12]}]
set_property PACKAGE_PIN AE8 [get_ports {ddr3_addr[13]}]
set_property PACKAGE_PIN AG9 [get_ports {ddr3_addr[14]}]
set_property PACKAGE_PIN AB9 [get_ports {ddr3_addr[15]}]
set_property PACKAGE_PIN AE10 [get_ports {ddr3_ba[0]}]
set_property PACKAGE_PIN AB12 [get_ports {ddr3_ba[1]}]
set_property PACKAGE_PIN AD8 [get_ports {ddr3_ba[2]}]
set_property PACKAGE_PIN AC12 [get_ports ddr3_cas_n]
set_property PACKAGE_PIN AD11 [get_ports ddr3_ck_n[1]] ;# SO_CK1_N
set_property PACKAGE_PIN AE11 [get_ports {ddr3_ck_p[0]}]
set_property PACKAGE_PIN AF11 [get_ports {ddr3_ck_n[0]}]
set_property PACKAGE_PIN AD12 [get_ports ddr3_ck_p[1]] ;# SO_CK1_P
set_property PACKAGE_PIN AA8 [get_ports {ddr3_cke[0]}]
set_property PACKAGE_PIN AB8 [get_ports ddr3_cke[1]] ;# SO_CKE1
set_property PACKAGE_PIN AH11 [get_ports {ddr3_cs_n[0]}]
set_property PACKAGE_PIN AA13 [get_ports ddr3_cs_n[1]] ;# SO_S1#
set_property PACKAGE_PIN AD4 [get_ports {ddr3_dm[0]}]
set_property PACKAGE_PIN AE1 [get_ports {ddr3_dm[1]}]
set_property PACKAGE_PIN AH4 [get_ports {ddr3_dm[2]}]
set_property PACKAGE_PIN AG7 [get_ports {ddr3_dm[3]}]
set_property PACKAGE_PIN AK13 [get_ports {ddr3_dm[4]}]
set_property PACKAGE_PIN AG15 [get_ports {ddr3_dm[5]}]
set_property PACKAGE_PIN AK19 [get_ports {ddr3_dm[6]}]
set_property PACKAGE_PIN AB19 [get_ports {ddr3_dm[7]}]
set_property PACKAGE_PIN AC4 [get_ports {ddr3_dq[0]}]
set_property PACKAGE_PIN AC5 [get_ports {ddr3_dq[1]}]
set_property PACKAGE_PIN AD6 [get_ports {ddr3_dq[2]}]
set_property PACKAGE_PIN AE6 [get_ports {ddr3_dq[3]}]
set_property PACKAGE_PIN AC1 [get_ports {ddr3_dq[4]}]
set_property PACKAGE_PIN AC2 [get_ports {ddr3_dq[5]}]
set_property PACKAGE_PIN AD3 [get_ports {ddr3_dq[6]}]
set_property PACKAGE_PIN AC7 [get_ports {ddr3_dq[7]}]
set_property PACKAGE_PIN AE5 [get_ports {ddr3_dq[8]}]
set_property PACKAGE_PIN AE4 [get_ports {ddr3_dq[9]}]
set_property PACKAGE_PIN AF5 [get_ports {ddr3_dq[10]}]
set_property PACKAGE_PIN AF6 [get_ports {ddr3_dq[11]}]
set_property PACKAGE_PIN AE3 [get_ports {ddr3_dq[12]}]
set_property PACKAGE_PIN AF3 [get_ports {ddr3_dq[13]}]
set_property PACKAGE_PIN AF1 [get_ports {ddr3_dq[14]}]
set_property PACKAGE_PIN AF2 [get_ports {ddr3_dq[15]}]
set_property PACKAGE_PIN AH5 [get_ports {ddr3_dq[16]}]
set_property PACKAGE_PIN AH6 [get_ports {ddr3_dq[17]}]
set_property PACKAGE_PIN AK3 [get_ports {ddr3_dq[18]}]
set_property PACKAGE_PIN AJ4 [get_ports {ddr3_dq[19]}]
set_property PACKAGE_PIN AJ1 [get_ports {ddr3_dq[20]}]
set_property PACKAGE_PIN AK1 [get_ports {ddr3_dq[21]}]
set_property PACKAGE_PIN AJ2 [get_ports {ddr3_dq[22]}]
set_property PACKAGE_PIN AJ3 [get_ports {ddr3_dq[23]}]
set_property PACKAGE_PIN AK4 [get_ports {ddr3_dq[24]}]
set_property PACKAGE_PIN AK5 [get_ports {ddr3_dq[25]}]
set_property PACKAGE_PIN AJ6 [get_ports {ddr3_dq[26]}]
set_property PACKAGE_PIN AK6 [get_ports {ddr3_dq[27]}]
set_property PACKAGE_PIN AF7 [get_ports {ddr3_dq[28]}]
set_property PACKAGE_PIN AF8 [get_ports {ddr3_dq[29]}]
set_property PACKAGE_PIN AJ8 [get_ports {ddr3_dq[30]}]
set_property PACKAGE_PIN AK8 [get_ports {ddr3_dq[31]}]
set_property PACKAGE_PIN AH12 [get_ports {ddr3_dq[32]}]
set_property PACKAGE_PIN AG13 [get_ports {ddr3_dq[33]}]
set_property PACKAGE_PIN AF12 [get_ports {ddr3_dq[34]}]
set_property PACKAGE_PIN AE13 [get_ports {ddr3_dq[35]}]
set_property PACKAGE_PIN AJ12 [get_ports {ddr3_dq[36]}]
set_property PACKAGE_PIN AJ13 [get_ports {ddr3_dq[37]}]
set_property PACKAGE_PIN AK14 [get_ports {ddr3_dq[38]}]
set_property PACKAGE_PIN AG12 [get_ports {ddr3_dq[39]}]
set_property PACKAGE_PIN AG14 [get_ports {ddr3_dq[40]}]
set_property PACKAGE_PIN AH15 [get_ports {ddr3_dq[41]}]
set_property PACKAGE_PIN AF15 [get_ports {ddr3_dq[42]}]
set_property PACKAGE_PIN AE16 [get_ports {ddr3_dq[43]}]
set_property PACKAGE_PIN AK15 [get_ports {ddr3_dq[44]}]
set_property PACKAGE_PIN AK16 [get_ports {ddr3_dq[45]}]
set_property PACKAGE_PIN AJ17 [get_ports {ddr3_dq[46]}]
set_property PACKAGE_PIN AH17 [get_ports {ddr3_dq[47]}]
set_property PACKAGE_PIN AF18 [get_ports {ddr3_dq[48]}]
set_property PACKAGE_PIN AG19 [get_ports {ddr3_dq[49]}]
set_property PACKAGE_PIN AE19 [get_ports {ddr3_dq[50]}]
set_property PACKAGE_PIN AD19 [get_ports {ddr3_dq[51]}]
set_property PACKAGE_PIN AF17 [get_ports {ddr3_dq[52]}]
set_property PACKAGE_PIN AG18 [get_ports {ddr3_dq[53]}]
set_property PACKAGE_PIN AJ19 [get_ports {ddr3_dq[54]}]
set_property PACKAGE_PIN AH19 [get_ports {ddr3_dq[55]}]
set_property PACKAGE_PIN AB17 [get_ports {ddr3_dq[56]}]
set_property PACKAGE_PIN AC19 [get_ports {ddr3_dq[57]}]
set_property PACKAGE_PIN AB18 [get_ports {ddr3_dq[58]}]
set_property PACKAGE_PIN AA18 [get_ports {ddr3_dq[59]}]
set_property PACKAGE_PIN AD16 [get_ports {ddr3_dq[60]}]
set_property PACKAGE_PIN AD17 [get_ports {ddr3_dq[61]}]
set_property PACKAGE_PIN AE18 [get_ports {ddr3_dq[62]}]
set_property PACKAGE_PIN AD18 [get_ports {ddr3_dq[63]}]
set_property PACKAGE_PIN AD2 [get_ports {ddr3_dqs_p[0]}]
set_property PACKAGE_PIN AD1 [get_ports {ddr3_dqs_n[0]}]
set_property PACKAGE_PIN AG4 [get_ports {ddr3_dqs_p[1]}]
set_property PACKAGE_PIN AG3 [get_ports {ddr3_dqs_n[1]}]
set_property PACKAGE_PIN AG2 [get_ports {ddr3_dqs_p[2]}]
set_property PACKAGE_PIN AH1 [get_ports {ddr3_dqs_n[2]}]
set_property PACKAGE_PIN AH7 [get_ports {ddr3_dqs_p[3]}]
set_property PACKAGE_PIN AJ7 [get_ports {ddr3_dqs_n[3]}]
set_property PACKAGE_PIN AH14 [get_ports {ddr3_dqs_p[4]}]
set_property PACKAGE_PIN AJ14 [get_ports {ddr3_dqs_n[4]}]
set_property PACKAGE_PIN AH16 [get_ports {ddr3_dqs_p[5]}]
set_property PACKAGE_PIN AJ16 [get_ports {ddr3_dqs_n[5]}]
set_property PACKAGE_PIN AJ18 [get_ports {ddr3_dqs_p[6]}]
set_property PACKAGE_PIN AK18 [get_ports {ddr3_dqs_n[6]}]
set_property -dict {PACKAGE_PIN AA28 IOSTANDARD LVCMOS33} [get_ports sodimm_i2c_scl] ;# SO_I2C_SCL
set_property -dict {PACKAGE_PIN AB28 IOSTANDARD LVCMOS33} [get_ports sodimm_i2c_sda] ;# SO_I2C_SDA
set_property PACKAGE_PIN Y19 [get_ports {ddr3_dqs_p[7]}]
set_property PACKAGE_PIN Y18 [get_ports {ddr3_dqs_n[7]}]
set_property PACKAGE_PIN AJ11 [get_ports {ddr3_odt[0]}]
set_property PACKAGE_PIN AK11 [get_ports ddr3_odt[1]] ;# SO_ODT1
set_property PACKAGE_PIN AA12 [get_ports ddr3_ras_n]
set_property PACKAGE_PIN AG5 [get_ports ddr3_reset_n]
set_property PACKAGE_PIN AC11 [get_ports ddr3_we_n]
set_property PACKAGE_PIN AG17 [get_ports sodimm_event_n] ;# SO_EVENT_B

# SFP+ 0 (MGT_3_115)
set_property PACKAGE_PIN K14 [get_ports {sfp_rx_los[0]}]
set_property PACKAGE_PIN K15 [get_ports {sfp_tx_dis[0]}]
set_property PACKAGE_PIN V5 [get_ports {sfp_rx_n[0]}]
set_property PACKAGE_PIN V6 [get_ports {sfp_rx_p[0]}]
set_property PACKAGE_PIN T1 [get_ports {sfp_tx_n[0]}]
set_property PACKAGE_PIN T2 [get_ports {sfp_tx_p[0]}]

# SFP+ 1 (MGT_0_115)
set_property PACKAGE_PIN L15 [get_ports {sfp_rx_los[1]}]
set_property PACKAGE_PIN J14 [get_ports {sfp_tx_dis[1]}]
set_property PACKAGE_PIN AA3 [get_ports {sfp_rx_n[1]}]
set_property PACKAGE_PIN AA4 [get_ports {sfp_rx_p[1]}]
set_property PACKAGE_PIN Y1 [get_ports {sfp_tx_n[1]}]
set_property PACKAGE_PIN Y2 [get_ports {sfp_tx_p[1]}]

# SFP+ 2 (MGT_1_115)
set_property PACKAGE_PIN L12 [get_ports {sfp_rx_los[2]}]
set_property PACKAGE_PIN J13 [get_ports {sfp_tx_dis[2]}]
set_property PACKAGE_PIN Y5 [get_ports {sfp_rx_n[2]}]
set_property PACKAGE_PIN Y6 [get_ports {sfp_rx_p[2]}]
set_property PACKAGE_PIN V1 [get_ports {sfp_tx_n[2]}]
set_property PACKAGE_PIN V2 [get_ports {sfp_tx_p[2]}]

# SFP+ 3 (MGT_2_115)
set_property PACKAGE_PIN K13 [get_ports {sfp_rx_los[3]}]
set_property PACKAGE_PIN J12 [get_ports {sfp_tx_dis[3]}]
set_property PACKAGE_PIN W3 [get_ports {sfp_rx_n[3]}]
set_property PACKAGE_PIN W4 [get_ports {sfp_rx_p[3]}]
set_property PACKAGE_PIN U3 [get_ports {sfp_tx_n[3]}]
set_property PACKAGE_PIN U4 [get_ports {sfp_tx_p[3]}]

# SFP+ Port LEDs
# D11 E11 J11 K11
# C11 F11 H11 L11
set_property PACKAGE_PIN D11 [get_ports {sfp_link[0]}]
set_property PACKAGE_PIN C11 [get_ports {sfp_link[1]}]
set_property PACKAGE_PIN J11 [get_ports {sfp_link[2]}]
set_property PACKAGE_PIN H11 [get_ports {sfp_link[3]}]
set_property PACKAGE_PIN E11 [get_ports {sfp_act[0]}]
set_property PACKAGE_PIN F11 [get_ports {sfp_act[1]}]
set_property PACKAGE_PIN K11 [get_ports {sfp_act[2]}]
set_property PACKAGE_PIN L11 [get_ports {sfp_act[3]}]

set_property IOSTANDARD LVCMOS33 [get_ports {sfp_rx_los[*]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sfp_tx_dis[*]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sfp_link[*]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sfp_act[*]}]

set_property -dict {PACKAGE_PIN R19 IOSTANDARD LVCMOS33} [get_ports sfp_scl]
set_property -dict {PACKAGE_PIN P19 IOSTANDARD LVCMOS33} [get_ports sfp_sda]

set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]

connect_debug_port u_ila_0/probe14 [get_nets [list {frame_datapath_i/in[meta][id]_64[0]} {frame_datapath_i/in[meta][id]_64[1]} {frame_datapath_i/in[meta][id]_64[2]}]]



create_debug_core u_ila_0 ila
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_0]
set_property ALL_PROBE_SAME_MU_CNT 1 [get_debug_cores u_ila_0]
set_property C_ADV_TRIGGER false [get_debug_cores u_ila_0]
set_property C_DATA_DEPTH 4096 [get_debug_cores u_ila_0]
set_property C_EN_STRG_QUAL false [get_debug_cores u_ila_0]
set_property C_INPUT_PIPE_STAGES 0 [get_debug_cores u_ila_0]
set_property C_TRIGIN_EN false [get_debug_cores u_ila_0]
set_property C_TRIGOUT_EN false [get_debug_cores u_ila_0]
set_property port_width 1 [get_debug_ports u_ila_0/clk]
connect_debug_port u_ila_0/clk [get_nets [list phy_mac_ip_cores.axi_ethernet_0_i/inst/pcs_pma/inst/core_clocking_i/userclk2]]
set_property PROBE_TYPE DATA [get_debug_ports u_ila_0/probe0]
set_property port_width 48 [get_debug_ports u_ila_0/probe0]
connect_debug_port u_ila_0/probe0 [get_nets [list {frame_datapath_i/in[data][dst][0]} {frame_datapath_i/in[data][dst][1]} {frame_datapath_i/in[data][dst][2]} {frame_datapath_i/in[data][dst][3]} {frame_datapath_i/in[data][dst][4]} {frame_datapath_i/in[data][dst][5]} {frame_datapath_i/in[data][dst][6]} {frame_datapath_i/in[data][dst][7]} {frame_datapath_i/in[data][dst][8]} {frame_datapath_i/in[data][dst][9]} {frame_datapath_i/in[data][dst][10]} {frame_datapath_i/in[data][dst][11]} {frame_datapath_i/in[data][dst][12]} {frame_datapath_i/in[data][dst][13]} {frame_datapath_i/in[data][dst][14]} {frame_datapath_i/in[data][dst][15]} {frame_datapath_i/in[data][dst][16]} {frame_datapath_i/in[data][dst][17]} {frame_datapath_i/in[data][dst][18]} {frame_datapath_i/in[data][dst][19]} {frame_datapath_i/in[data][dst][20]} {frame_datapath_i/in[data][dst][21]} {frame_datapath_i/in[data][dst][22]} {frame_datapath_i/in[data][dst][23]} {frame_datapath_i/in[data][dst][24]} {frame_datapath_i/in[data][dst][25]} {frame_datapath_i/in[data][dst][26]} {frame_datapath_i/in[data][dst][27]} {frame_datapath_i/in[data][dst][28]} {frame_datapath_i/in[data][dst][29]} {frame_datapath_i/in[data][dst][30]} {frame_datapath_i/in[data][dst][31]} {frame_datapath_i/in[data][dst][32]} {frame_datapath_i/in[data][dst][33]} {frame_datapath_i/in[data][dst][34]} {frame_datapath_i/in[data][dst][35]} {frame_datapath_i/in[data][dst][36]} {frame_datapath_i/in[data][dst][37]} {frame_datapath_i/in[data][dst][38]} {frame_datapath_i/in[data][dst][39]} {frame_datapath_i/in[data][dst][40]} {frame_datapath_i/in[data][dst][41]} {frame_datapath_i/in[data][dst][42]} {frame_datapath_i/in[data][dst][43]} {frame_datapath_i/in[data][dst][44]} {frame_datapath_i/in[data][dst][45]} {frame_datapath_i/in[data][dst][46]} {frame_datapath_i/in[data][dst][47]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA [get_debug_ports u_ila_0/probe1]
set_property port_width 16 [get_debug_ports u_ila_0/probe1]
connect_debug_port u_ila_0/probe1 [get_nets [list {frame_datapath_i/in[data][ethertype][0]} {frame_datapath_i/in[data][ethertype][1]} {frame_datapath_i/in[data][ethertype][2]} {frame_datapath_i/in[data][ethertype][3]} {frame_datapath_i/in[data][ethertype][4]} {frame_datapath_i/in[data][ethertype][5]} {frame_datapath_i/in[data][ethertype][6]} {frame_datapath_i/in[data][ethertype][7]} {frame_datapath_i/in[data][ethertype][8]} {frame_datapath_i/in[data][ethertype][9]} {frame_datapath_i/in[data][ethertype][10]} {frame_datapath_i/in[data][ethertype][11]} {frame_datapath_i/in[data][ethertype][12]} {frame_datapath_i/in[data][ethertype][13]} {frame_datapath_i/in[data][ethertype][14]} {frame_datapath_i/in[data][ethertype][15]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA [get_debug_ports u_ila_0/probe2]
set_property port_width 24 [get_debug_ports u_ila_0/probe2]
connect_debug_port u_ila_0/probe2 [get_nets [list {frame_datapath_i/in[data][ip6][flow_lo][0]} {frame_datapath_i/in[data][ip6][flow_lo][1]} {frame_datapath_i/in[data][ip6][flow_lo][2]} {frame_datapath_i/in[data][ip6][flow_lo][3]} {frame_datapath_i/in[data][ip6][flow_lo][4]} {frame_datapath_i/in[data][ip6][flow_lo][5]} {frame_datapath_i/in[data][ip6][flow_lo][6]} {frame_datapath_i/in[data][ip6][flow_lo][7]} {frame_datapath_i/in[data][ip6][flow_lo][8]} {frame_datapath_i/in[data][ip6][flow_lo][9]} {frame_datapath_i/in[data][ip6][flow_lo][10]} {frame_datapath_i/in[data][ip6][flow_lo][11]} {frame_datapath_i/in[data][ip6][flow_lo][12]} {frame_datapath_i/in[data][ip6][flow_lo][13]} {frame_datapath_i/in[data][ip6][flow_lo][14]} {frame_datapath_i/in[data][ip6][flow_lo][15]} {frame_datapath_i/in[data][ip6][flow_lo][16]} {frame_datapath_i/in[data][ip6][flow_lo][17]} {frame_datapath_i/in[data][ip6][flow_lo][18]} {frame_datapath_i/in[data][ip6][flow_lo][19]} {frame_datapath_i/in[data][ip6][flow_lo][20]} {frame_datapath_i/in[data][ip6][flow_lo][21]} {frame_datapath_i/in[data][ip6][flow_lo][22]} {frame_datapath_i/in[data][ip6][flow_lo][23]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA [get_debug_ports u_ila_0/probe3]
set_property port_width 4 [get_debug_ports u_ila_0/probe3]
connect_debug_port u_ila_0/probe3 [get_nets [list {frame_datapath_i/in[data][ip6][flow_hi][0]} {frame_datapath_i/in[data][ip6][flow_hi][1]} {frame_datapath_i/in[data][ip6][flow_hi][2]} {frame_datapath_i/in[data][ip6][flow_hi][3]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA [get_debug_ports u_ila_0/probe4]
set_property port_width 8 [get_debug_ports u_ila_0/probe4]
connect_debug_port u_ila_0/probe4 [get_nets [list {frame_datapath_i/in[data][ip6][hop_limit][0]} {frame_datapath_i/in[data][ip6][hop_limit][1]} {frame_datapath_i/in[data][ip6][hop_limit][2]} {frame_datapath_i/in[data][ip6][hop_limit][3]} {frame_datapath_i/in[data][ip6][hop_limit][4]} {frame_datapath_i/in[data][ip6][hop_limit][5]} {frame_datapath_i/in[data][ip6][hop_limit][6]} {frame_datapath_i/in[data][ip6][hop_limit][7]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA [get_debug_ports u_ila_0/probe5]
set_property port_width 8 [get_debug_ports u_ila_0/probe5]
connect_debug_port u_ila_0/probe5 [get_nets [list {frame_datapath_i/in[data][ip6][next_hdr][0]} {frame_datapath_i/in[data][ip6][next_hdr][1]} {frame_datapath_i/in[data][ip6][next_hdr][2]} {frame_datapath_i/in[data][ip6][next_hdr][3]} {frame_datapath_i/in[data][ip6][next_hdr][4]} {frame_datapath_i/in[data][ip6][next_hdr][5]} {frame_datapath_i/in[data][ip6][next_hdr][6]} {frame_datapath_i/in[data][ip6][next_hdr][7]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA [get_debug_ports u_ila_0/probe6]
set_property port_width 128 [get_debug_ports u_ila_0/probe6]
connect_debug_port u_ila_0/probe6 [get_nets [list {frame_datapath_i/in[data][ip6][dst][0]} {frame_datapath_i/in[data][ip6][dst][1]} {frame_datapath_i/in[data][ip6][dst][2]} {frame_datapath_i/in[data][ip6][dst][3]} {frame_datapath_i/in[data][ip6][dst][4]} {frame_datapath_i/in[data][ip6][dst][5]} {frame_datapath_i/in[data][ip6][dst][6]} {frame_datapath_i/in[data][ip6][dst][7]} {frame_datapath_i/in[data][ip6][dst][8]} {frame_datapath_i/in[data][ip6][dst][9]} {frame_datapath_i/in[data][ip6][dst][10]} {frame_datapath_i/in[data][ip6][dst][11]} {frame_datapath_i/in[data][ip6][dst][12]} {frame_datapath_i/in[data][ip6][dst][13]} {frame_datapath_i/in[data][ip6][dst][14]} {frame_datapath_i/in[data][ip6][dst][15]} {frame_datapath_i/in[data][ip6][dst][16]} {frame_datapath_i/in[data][ip6][dst][17]} {frame_datapath_i/in[data][ip6][dst][18]} {frame_datapath_i/in[data][ip6][dst][19]} {frame_datapath_i/in[data][ip6][dst][20]} {frame_datapath_i/in[data][ip6][dst][21]} {frame_datapath_i/in[data][ip6][dst][22]} {frame_datapath_i/in[data][ip6][dst][23]} {frame_datapath_i/in[data][ip6][dst][24]} {frame_datapath_i/in[data][ip6][dst][25]} {frame_datapath_i/in[data][ip6][dst][26]} {frame_datapath_i/in[data][ip6][dst][27]} {frame_datapath_i/in[data][ip6][dst][28]} {frame_datapath_i/in[data][ip6][dst][29]} {frame_datapath_i/in[data][ip6][dst][30]} {frame_datapath_i/in[data][ip6][dst][31]} {frame_datapath_i/in[data][ip6][dst][32]} {frame_datapath_i/in[data][ip6][dst][33]} {frame_datapath_i/in[data][ip6][dst][34]} {frame_datapath_i/in[data][ip6][dst][35]} {frame_datapath_i/in[data][ip6][dst][36]} {frame_datapath_i/in[data][ip6][dst][37]} {frame_datapath_i/in[data][ip6][dst][38]} {frame_datapath_i/in[data][ip6][dst][39]} {frame_datapath_i/in[data][ip6][dst][40]} {frame_datapath_i/in[data][ip6][dst][41]} {frame_datapath_i/in[data][ip6][dst][42]} {frame_datapath_i/in[data][ip6][dst][43]} {frame_datapath_i/in[data][ip6][dst][44]} {frame_datapath_i/in[data][ip6][dst][45]} {frame_datapath_i/in[data][ip6][dst][46]} {frame_datapath_i/in[data][ip6][dst][47]} {frame_datapath_i/in[data][ip6][dst][48]} {frame_datapath_i/in[data][ip6][dst][49]} {frame_datapath_i/in[data][ip6][dst][50]} {frame_datapath_i/in[data][ip6][dst][51]} {frame_datapath_i/in[data][ip6][dst][52]} {frame_datapath_i/in[data][ip6][dst][53]} {frame_datapath_i/in[data][ip6][dst][54]} {frame_datapath_i/in[data][ip6][dst][55]} {frame_datapath_i/in[data][ip6][dst][56]} {frame_datapath_i/in[data][ip6][dst][57]} {frame_datapath_i/in[data][ip6][dst][58]} {frame_datapath_i/in[data][ip6][dst][59]} {frame_datapath_i/in[data][ip6][dst][60]} {frame_datapath_i/in[data][ip6][dst][61]} {frame_datapath_i/in[data][ip6][dst][62]} {frame_datapath_i/in[data][ip6][dst][63]} {frame_datapath_i/in[data][ip6][dst][64]} {frame_datapath_i/in[data][ip6][dst][65]} {frame_datapath_i/in[data][ip6][dst][66]} {frame_datapath_i/in[data][ip6][dst][67]} {frame_datapath_i/in[data][ip6][dst][68]} {frame_datapath_i/in[data][ip6][dst][69]} {frame_datapath_i/in[data][ip6][dst][70]} {frame_datapath_i/in[data][ip6][dst][71]} {frame_datapath_i/in[data][ip6][dst][72]} {frame_datapath_i/in[data][ip6][dst][73]} {frame_datapath_i/in[data][ip6][dst][74]} {frame_datapath_i/in[data][ip6][dst][75]} {frame_datapath_i/in[data][ip6][dst][76]} {frame_datapath_i/in[data][ip6][dst][77]} {frame_datapath_i/in[data][ip6][dst][78]} {frame_datapath_i/in[data][ip6][dst][79]} {frame_datapath_i/in[data][ip6][dst][80]} {frame_datapath_i/in[data][ip6][dst][81]} {frame_datapath_i/in[data][ip6][dst][82]} {frame_datapath_i/in[data][ip6][dst][83]} {frame_datapath_i/in[data][ip6][dst][84]} {frame_datapath_i/in[data][ip6][dst][85]} {frame_datapath_i/in[data][ip6][dst][86]} {frame_datapath_i/in[data][ip6][dst][87]} {frame_datapath_i/in[data][ip6][dst][88]} {frame_datapath_i/in[data][ip6][dst][89]} {frame_datapath_i/in[data][ip6][dst][90]} {frame_datapath_i/in[data][ip6][dst][91]} {frame_datapath_i/in[data][ip6][dst][92]} {frame_datapath_i/in[data][ip6][dst][93]} {frame_datapath_i/in[data][ip6][dst][94]} {frame_datapath_i/in[data][ip6][dst][95]} {frame_datapath_i/in[data][ip6][dst][96]} {frame_datapath_i/in[data][ip6][dst][97]} {frame_datapath_i/in[data][ip6][dst][98]} {frame_datapath_i/in[data][ip6][dst][99]} {frame_datapath_i/in[data][ip6][dst][100]} {frame_datapath_i/in[data][ip6][dst][101]} {frame_datapath_i/in[data][ip6][dst][102]} {frame_datapath_i/in[data][ip6][dst][103]} {frame_datapath_i/in[data][ip6][dst][104]} {frame_datapath_i/in[data][ip6][dst][105]} {frame_datapath_i/in[data][ip6][dst][106]} {frame_datapath_i/in[data][ip6][dst][107]} {frame_datapath_i/in[data][ip6][dst][108]} {frame_datapath_i/in[data][ip6][dst][109]} {frame_datapath_i/in[data][ip6][dst][110]} {frame_datapath_i/in[data][ip6][dst][111]} {frame_datapath_i/in[data][ip6][dst][112]} {frame_datapath_i/in[data][ip6][dst][113]} {frame_datapath_i/in[data][ip6][dst][114]} {frame_datapath_i/in[data][ip6][dst][115]} {frame_datapath_i/in[data][ip6][dst][116]} {frame_datapath_i/in[data][ip6][dst][117]} {frame_datapath_i/in[data][ip6][dst][118]} {frame_datapath_i/in[data][ip6][dst][119]} {frame_datapath_i/in[data][ip6][dst][120]} {frame_datapath_i/in[data][ip6][dst][121]} {frame_datapath_i/in[data][ip6][dst][122]} {frame_datapath_i/in[data][ip6][dst][123]} {frame_datapath_i/in[data][ip6][dst][124]} {frame_datapath_i/in[data][ip6][dst][125]} {frame_datapath_i/in[data][ip6][dst][126]} {frame_datapath_i/in[data][ip6][dst][127]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA [get_debug_ports u_ila_0/probe7]
set_property port_width 128 [get_debug_ports u_ila_0/probe7]
connect_debug_port u_ila_0/probe7 [get_nets [list {frame_datapath_i/in[data][ip6][src][0]} {frame_datapath_i/in[data][ip6][src][1]} {frame_datapath_i/in[data][ip6][src][2]} {frame_datapath_i/in[data][ip6][src][3]} {frame_datapath_i/in[data][ip6][src][4]} {frame_datapath_i/in[data][ip6][src][5]} {frame_datapath_i/in[data][ip6][src][6]} {frame_datapath_i/in[data][ip6][src][7]} {frame_datapath_i/in[data][ip6][src][8]} {frame_datapath_i/in[data][ip6][src][9]} {frame_datapath_i/in[data][ip6][src][10]} {frame_datapath_i/in[data][ip6][src][11]} {frame_datapath_i/in[data][ip6][src][12]} {frame_datapath_i/in[data][ip6][src][13]} {frame_datapath_i/in[data][ip6][src][14]} {frame_datapath_i/in[data][ip6][src][15]} {frame_datapath_i/in[data][ip6][src][16]} {frame_datapath_i/in[data][ip6][src][17]} {frame_datapath_i/in[data][ip6][src][18]} {frame_datapath_i/in[data][ip6][src][19]} {frame_datapath_i/in[data][ip6][src][20]} {frame_datapath_i/in[data][ip6][src][21]} {frame_datapath_i/in[data][ip6][src][22]} {frame_datapath_i/in[data][ip6][src][23]} {frame_datapath_i/in[data][ip6][src][24]} {frame_datapath_i/in[data][ip6][src][25]} {frame_datapath_i/in[data][ip6][src][26]} {frame_datapath_i/in[data][ip6][src][27]} {frame_datapath_i/in[data][ip6][src][28]} {frame_datapath_i/in[data][ip6][src][29]} {frame_datapath_i/in[data][ip6][src][30]} {frame_datapath_i/in[data][ip6][src][31]} {frame_datapath_i/in[data][ip6][src][32]} {frame_datapath_i/in[data][ip6][src][33]} {frame_datapath_i/in[data][ip6][src][34]} {frame_datapath_i/in[data][ip6][src][35]} {frame_datapath_i/in[data][ip6][src][36]} {frame_datapath_i/in[data][ip6][src][37]} {frame_datapath_i/in[data][ip6][src][38]} {frame_datapath_i/in[data][ip6][src][39]} {frame_datapath_i/in[data][ip6][src][40]} {frame_datapath_i/in[data][ip6][src][41]} {frame_datapath_i/in[data][ip6][src][42]} {frame_datapath_i/in[data][ip6][src][43]} {frame_datapath_i/in[data][ip6][src][44]} {frame_datapath_i/in[data][ip6][src][45]} {frame_datapath_i/in[data][ip6][src][46]} {frame_datapath_i/in[data][ip6][src][47]} {frame_datapath_i/in[data][ip6][src][48]} {frame_datapath_i/in[data][ip6][src][49]} {frame_datapath_i/in[data][ip6][src][50]} {frame_datapath_i/in[data][ip6][src][51]} {frame_datapath_i/in[data][ip6][src][52]} {frame_datapath_i/in[data][ip6][src][53]} {frame_datapath_i/in[data][ip6][src][54]} {frame_datapath_i/in[data][ip6][src][55]} {frame_datapath_i/in[data][ip6][src][56]} {frame_datapath_i/in[data][ip6][src][57]} {frame_datapath_i/in[data][ip6][src][58]} {frame_datapath_i/in[data][ip6][src][59]} {frame_datapath_i/in[data][ip6][src][60]} {frame_datapath_i/in[data][ip6][src][61]} {frame_datapath_i/in[data][ip6][src][62]} {frame_datapath_i/in[data][ip6][src][63]} {frame_datapath_i/in[data][ip6][src][64]} {frame_datapath_i/in[data][ip6][src][65]} {frame_datapath_i/in[data][ip6][src][66]} {frame_datapath_i/in[data][ip6][src][67]} {frame_datapath_i/in[data][ip6][src][68]} {frame_datapath_i/in[data][ip6][src][69]} {frame_datapath_i/in[data][ip6][src][70]} {frame_datapath_i/in[data][ip6][src][71]} {frame_datapath_i/in[data][ip6][src][72]} {frame_datapath_i/in[data][ip6][src][73]} {frame_datapath_i/in[data][ip6][src][74]} {frame_datapath_i/in[data][ip6][src][75]} {frame_datapath_i/in[data][ip6][src][76]} {frame_datapath_i/in[data][ip6][src][77]} {frame_datapath_i/in[data][ip6][src][78]} {frame_datapath_i/in[data][ip6][src][79]} {frame_datapath_i/in[data][ip6][src][80]} {frame_datapath_i/in[data][ip6][src][81]} {frame_datapath_i/in[data][ip6][src][82]} {frame_datapath_i/in[data][ip6][src][83]} {frame_datapath_i/in[data][ip6][src][84]} {frame_datapath_i/in[data][ip6][src][85]} {frame_datapath_i/in[data][ip6][src][86]} {frame_datapath_i/in[data][ip6][src][87]} {frame_datapath_i/in[data][ip6][src][88]} {frame_datapath_i/in[data][ip6][src][89]} {frame_datapath_i/in[data][ip6][src][90]} {frame_datapath_i/in[data][ip6][src][91]} {frame_datapath_i/in[data][ip6][src][92]} {frame_datapath_i/in[data][ip6][src][93]} {frame_datapath_i/in[data][ip6][src][94]} {frame_datapath_i/in[data][ip6][src][95]} {frame_datapath_i/in[data][ip6][src][96]} {frame_datapath_i/in[data][ip6][src][97]} {frame_datapath_i/in[data][ip6][src][98]} {frame_datapath_i/in[data][ip6][src][99]} {frame_datapath_i/in[data][ip6][src][100]} {frame_datapath_i/in[data][ip6][src][101]} {frame_datapath_i/in[data][ip6][src][102]} {frame_datapath_i/in[data][ip6][src][103]} {frame_datapath_i/in[data][ip6][src][104]} {frame_datapath_i/in[data][ip6][src][105]} {frame_datapath_i/in[data][ip6][src][106]} {frame_datapath_i/in[data][ip6][src][107]} {frame_datapath_i/in[data][ip6][src][108]} {frame_datapath_i/in[data][ip6][src][109]} {frame_datapath_i/in[data][ip6][src][110]} {frame_datapath_i/in[data][ip6][src][111]} {frame_datapath_i/in[data][ip6][src][112]} {frame_datapath_i/in[data][ip6][src][113]} {frame_datapath_i/in[data][ip6][src][114]} {frame_datapath_i/in[data][ip6][src][115]} {frame_datapath_i/in[data][ip6][src][116]} {frame_datapath_i/in[data][ip6][src][117]} {frame_datapath_i/in[data][ip6][src][118]} {frame_datapath_i/in[data][ip6][src][119]} {frame_datapath_i/in[data][ip6][src][120]} {frame_datapath_i/in[data][ip6][src][121]} {frame_datapath_i/in[data][ip6][src][122]} {frame_datapath_i/in[data][ip6][src][123]} {frame_datapath_i/in[data][ip6][src][124]} {frame_datapath_i/in[data][ip6][src][125]} {frame_datapath_i/in[data][ip6][src][126]} {frame_datapath_i/in[data][ip6][src][127]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA [get_debug_ports u_ila_0/probe8]
set_property port_width 4 [get_debug_ports u_ila_0/probe8]
connect_debug_port u_ila_0/probe8 [get_nets [list {frame_datapath_i/in[data][ip6][version][0]} {frame_datapath_i/in[data][ip6][version][1]} {frame_datapath_i/in[data][ip6][version][2]} {frame_datapath_i/in[data][ip6][version][3]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA [get_debug_ports u_ila_0/probe9]
set_property port_width 3 [get_debug_ports u_ila_0/probe9]
connect_debug_port u_ila_0/probe9 [get_nets [list {frame_datapath_i/in[meta][id][0]} {frame_datapath_i/in[meta][id][1]} {frame_datapath_i/in[meta][id][2]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA [get_debug_ports u_ila_0/probe10]
set_property port_width 48 [get_debug_ports u_ila_0/probe10]
connect_debug_port u_ila_0/probe10 [get_nets [list {frame_datapath_i/in[data][src][0]} {frame_datapath_i/in[data][src][1]} {frame_datapath_i/in[data][src][2]} {frame_datapath_i/in[data][src][3]} {frame_datapath_i/in[data][src][4]} {frame_datapath_i/in[data][src][5]} {frame_datapath_i/in[data][src][6]} {frame_datapath_i/in[data][src][7]} {frame_datapath_i/in[data][src][8]} {frame_datapath_i/in[data][src][9]} {frame_datapath_i/in[data][src][10]} {frame_datapath_i/in[data][src][11]} {frame_datapath_i/in[data][src][12]} {frame_datapath_i/in[data][src][13]} {frame_datapath_i/in[data][src][14]} {frame_datapath_i/in[data][src][15]} {frame_datapath_i/in[data][src][16]} {frame_datapath_i/in[data][src][17]} {frame_datapath_i/in[data][src][18]} {frame_datapath_i/in[data][src][19]} {frame_datapath_i/in[data][src][20]} {frame_datapath_i/in[data][src][21]} {frame_datapath_i/in[data][src][22]} {frame_datapath_i/in[data][src][23]} {frame_datapath_i/in[data][src][24]} {frame_datapath_i/in[data][src][25]} {frame_datapath_i/in[data][src][26]} {frame_datapath_i/in[data][src][27]} {frame_datapath_i/in[data][src][28]} {frame_datapath_i/in[data][src][29]} {frame_datapath_i/in[data][src][30]} {frame_datapath_i/in[data][src][31]} {frame_datapath_i/in[data][src][32]} {frame_datapath_i/in[data][src][33]} {frame_datapath_i/in[data][src][34]} {frame_datapath_i/in[data][src][35]} {frame_datapath_i/in[data][src][36]} {frame_datapath_i/in[data][src][37]} {frame_datapath_i/in[data][src][38]} {frame_datapath_i/in[data][src][39]} {frame_datapath_i/in[data][src][40]} {frame_datapath_i/in[data][src][41]} {frame_datapath_i/in[data][src][42]} {frame_datapath_i/in[data][src][43]} {frame_datapath_i/in[data][src][44]} {frame_datapath_i/in[data][src][45]} {frame_datapath_i/in[data][src][46]} {frame_datapath_i/in[data][src][47]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA [get_debug_ports u_ila_0/probe11]
set_property port_width 3 [get_debug_ports u_ila_0/probe11]
connect_debug_port u_ila_0/probe11 [get_nets [list {frame_datapath_i/in[meta][id]_65[0]} {frame_datapath_i/in[meta][id]_65[1]} {frame_datapath_i/in[meta][id]_65[2]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA [get_debug_ports u_ila_0/probe12]
set_property port_width 56 [get_debug_ports u_ila_0/probe12]
connect_debug_port u_ila_0/probe12 [get_nets [list {frame_datapath_i/in[keep][0]} {frame_datapath_i/in[keep][1]} {frame_datapath_i/in[keep][2]} {frame_datapath_i/in[keep][3]} {frame_datapath_i/in[keep][4]} {frame_datapath_i/in[keep][5]} {frame_datapath_i/in[keep][6]} {frame_datapath_i/in[keep][7]} {frame_datapath_i/in[keep][8]} {frame_datapath_i/in[keep][9]} {frame_datapath_i/in[keep][10]} {frame_datapath_i/in[keep][11]} {frame_datapath_i/in[keep][12]} {frame_datapath_i/in[keep][13]} {frame_datapath_i/in[keep][14]} {frame_datapath_i/in[keep][15]} {frame_datapath_i/in[keep][16]} {frame_datapath_i/in[keep][17]} {frame_datapath_i/in[keep][18]} {frame_datapath_i/in[keep][19]} {frame_datapath_i/in[keep][20]} {frame_datapath_i/in[keep][21]} {frame_datapath_i/in[keep][22]} {frame_datapath_i/in[keep][23]} {frame_datapath_i/in[keep][24]} {frame_datapath_i/in[keep][25]} {frame_datapath_i/in[keep][26]} {frame_datapath_i/in[keep][27]} {frame_datapath_i/in[keep][28]} {frame_datapath_i/in[keep][29]} {frame_datapath_i/in[keep][30]} {frame_datapath_i/in[keep][31]} {frame_datapath_i/in[keep][32]} {frame_datapath_i/in[keep][33]} {frame_datapath_i/in[keep][34]} {frame_datapath_i/in[keep][35]} {frame_datapath_i/in[keep][36]} {frame_datapath_i/in[keep][37]} {frame_datapath_i/in[keep][38]} {frame_datapath_i/in[keep][39]} {frame_datapath_i/in[keep][40]} {frame_datapath_i/in[keep][41]} {frame_datapath_i/in[keep][42]} {frame_datapath_i/in[keep][43]} {frame_datapath_i/in[keep][44]} {frame_datapath_i/in[keep][45]} {frame_datapath_i/in[keep][46]} {frame_datapath_i/in[keep][47]} {frame_datapath_i/in[keep][48]} {frame_datapath_i/in[keep][49]} {frame_datapath_i/in[keep][50]} {frame_datapath_i/in[keep][51]} {frame_datapath_i/in[keep][52]} {frame_datapath_i/in[keep][53]} {frame_datapath_i/in[keep][54]} {frame_datapath_i/in[keep][55]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA [get_debug_ports u_ila_0/probe13]
set_property port_width 41 [get_debug_ports u_ila_0/probe13]
connect_debug_port u_ila_0/probe13 [get_nets [list {frame_datapath_i/out[data][dst][0]} {frame_datapath_i/out[data][dst][1]} {frame_datapath_i/out[data][dst][2]} {frame_datapath_i/out[data][dst][3]} {frame_datapath_i/out[data][dst][4]} {frame_datapath_i/out[data][dst][5]} {frame_datapath_i/out[data][dst][6]} {frame_datapath_i/out[data][dst][7]} {frame_datapath_i/out[data][dst][8]} {frame_datapath_i/out[data][dst][9]} {frame_datapath_i/out[data][dst][10]} {frame_datapath_i/out[data][dst][11]} {frame_datapath_i/out[data][dst][12]} {frame_datapath_i/out[data][dst][13]} {frame_datapath_i/out[data][dst][14]} {frame_datapath_i/out[data][dst][15]} {frame_datapath_i/out[data][dst][16]} {frame_datapath_i/out[data][dst][24]} {frame_datapath_i/out[data][dst][25]} {frame_datapath_i/out[data][dst][26]} {frame_datapath_i/out[data][dst][27]} {frame_datapath_i/out[data][dst][28]} {frame_datapath_i/out[data][dst][29]} {frame_datapath_i/out[data][dst][30]} {frame_datapath_i/out[data][dst][31]} {frame_datapath_i/out[data][dst][32]} {frame_datapath_i/out[data][dst][33]} {frame_datapath_i/out[data][dst][34]} {frame_datapath_i/out[data][dst][35]} {frame_datapath_i/out[data][dst][36]} {frame_datapath_i/out[data][dst][37]} {frame_datapath_i/out[data][dst][38]} {frame_datapath_i/out[data][dst][39]} {frame_datapath_i/out[data][dst][40]} {frame_datapath_i/out[data][dst][41]} {frame_datapath_i/out[data][dst][42]} {frame_datapath_i/out[data][dst][43]} {frame_datapath_i/out[data][dst][44]} {frame_datapath_i/out[data][dst][45]} {frame_datapath_i/out[data][dst][46]} {frame_datapath_i/out[data][dst][47]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA [get_debug_ports u_ila_0/probe14]
set_property port_width 16 [get_debug_ports u_ila_0/probe14]
connect_debug_port u_ila_0/probe14 [get_nets [list {frame_datapath_i/out[data][ethertype][0]} {frame_datapath_i/out[data][ethertype][1]} {frame_datapath_i/out[data][ethertype][2]} {frame_datapath_i/out[data][ethertype][3]} {frame_datapath_i/out[data][ethertype][4]} {frame_datapath_i/out[data][ethertype][5]} {frame_datapath_i/out[data][ethertype][6]} {frame_datapath_i/out[data][ethertype][7]} {frame_datapath_i/out[data][ethertype][8]} {frame_datapath_i/out[data][ethertype][9]} {frame_datapath_i/out[data][ethertype][10]} {frame_datapath_i/out[data][ethertype][11]} {frame_datapath_i/out[data][ethertype][12]} {frame_datapath_i/out[data][ethertype][13]} {frame_datapath_i/out[data][ethertype][14]} {frame_datapath_i/out[data][ethertype][15]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA [get_debug_ports u_ila_0/probe15]
set_property port_width 128 [get_debug_ports u_ila_0/probe15]
connect_debug_port u_ila_0/probe15 [get_nets [list {frame_datapath_i/out[data][ip6][dst][0]} {frame_datapath_i/out[data][ip6][dst][1]} {frame_datapath_i/out[data][ip6][dst][2]} {frame_datapath_i/out[data][ip6][dst][3]} {frame_datapath_i/out[data][ip6][dst][4]} {frame_datapath_i/out[data][ip6][dst][5]} {frame_datapath_i/out[data][ip6][dst][6]} {frame_datapath_i/out[data][ip6][dst][7]} {frame_datapath_i/out[data][ip6][dst][8]} {frame_datapath_i/out[data][ip6][dst][9]} {frame_datapath_i/out[data][ip6][dst][10]} {frame_datapath_i/out[data][ip6][dst][11]} {frame_datapath_i/out[data][ip6][dst][12]} {frame_datapath_i/out[data][ip6][dst][13]} {frame_datapath_i/out[data][ip6][dst][14]} {frame_datapath_i/out[data][ip6][dst][15]} {frame_datapath_i/out[data][ip6][dst][16]} {frame_datapath_i/out[data][ip6][dst][17]} {frame_datapath_i/out[data][ip6][dst][18]} {frame_datapath_i/out[data][ip6][dst][19]} {frame_datapath_i/out[data][ip6][dst][20]} {frame_datapath_i/out[data][ip6][dst][21]} {frame_datapath_i/out[data][ip6][dst][22]} {frame_datapath_i/out[data][ip6][dst][23]} {frame_datapath_i/out[data][ip6][dst][24]} {frame_datapath_i/out[data][ip6][dst][25]} {frame_datapath_i/out[data][ip6][dst][26]} {frame_datapath_i/out[data][ip6][dst][27]} {frame_datapath_i/out[data][ip6][dst][28]} {frame_datapath_i/out[data][ip6][dst][29]} {frame_datapath_i/out[data][ip6][dst][30]} {frame_datapath_i/out[data][ip6][dst][31]} {frame_datapath_i/out[data][ip6][dst][32]} {frame_datapath_i/out[data][ip6][dst][33]} {frame_datapath_i/out[data][ip6][dst][34]} {frame_datapath_i/out[data][ip6][dst][35]} {frame_datapath_i/out[data][ip6][dst][36]} {frame_datapath_i/out[data][ip6][dst][37]} {frame_datapath_i/out[data][ip6][dst][38]} {frame_datapath_i/out[data][ip6][dst][39]} {frame_datapath_i/out[data][ip6][dst][40]} {frame_datapath_i/out[data][ip6][dst][41]} {frame_datapath_i/out[data][ip6][dst][42]} {frame_datapath_i/out[data][ip6][dst][43]} {frame_datapath_i/out[data][ip6][dst][44]} {frame_datapath_i/out[data][ip6][dst][45]} {frame_datapath_i/out[data][ip6][dst][46]} {frame_datapath_i/out[data][ip6][dst][47]} {frame_datapath_i/out[data][ip6][dst][48]} {frame_datapath_i/out[data][ip6][dst][49]} {frame_datapath_i/out[data][ip6][dst][50]} {frame_datapath_i/out[data][ip6][dst][51]} {frame_datapath_i/out[data][ip6][dst][52]} {frame_datapath_i/out[data][ip6][dst][53]} {frame_datapath_i/out[data][ip6][dst][54]} {frame_datapath_i/out[data][ip6][dst][55]} {frame_datapath_i/out[data][ip6][dst][56]} {frame_datapath_i/out[data][ip6][dst][57]} {frame_datapath_i/out[data][ip6][dst][58]} {frame_datapath_i/out[data][ip6][dst][59]} {frame_datapath_i/out[data][ip6][dst][60]} {frame_datapath_i/out[data][ip6][dst][61]} {frame_datapath_i/out[data][ip6][dst][62]} {frame_datapath_i/out[data][ip6][dst][63]} {frame_datapath_i/out[data][ip6][dst][64]} {frame_datapath_i/out[data][ip6][dst][65]} {frame_datapath_i/out[data][ip6][dst][66]} {frame_datapath_i/out[data][ip6][dst][67]} {frame_datapath_i/out[data][ip6][dst][68]} {frame_datapath_i/out[data][ip6][dst][69]} {frame_datapath_i/out[data][ip6][dst][70]} {frame_datapath_i/out[data][ip6][dst][71]} {frame_datapath_i/out[data][ip6][dst][72]} {frame_datapath_i/out[data][ip6][dst][73]} {frame_datapath_i/out[data][ip6][dst][74]} {frame_datapath_i/out[data][ip6][dst][75]} {frame_datapath_i/out[data][ip6][dst][76]} {frame_datapath_i/out[data][ip6][dst][77]} {frame_datapath_i/out[data][ip6][dst][78]} {frame_datapath_i/out[data][ip6][dst][79]} {frame_datapath_i/out[data][ip6][dst][80]} {frame_datapath_i/out[data][ip6][dst][81]} {frame_datapath_i/out[data][ip6][dst][82]} {frame_datapath_i/out[data][ip6][dst][83]} {frame_datapath_i/out[data][ip6][dst][84]} {frame_datapath_i/out[data][ip6][dst][85]} {frame_datapath_i/out[data][ip6][dst][86]} {frame_datapath_i/out[data][ip6][dst][87]} {frame_datapath_i/out[data][ip6][dst][88]} {frame_datapath_i/out[data][ip6][dst][89]} {frame_datapath_i/out[data][ip6][dst][90]} {frame_datapath_i/out[data][ip6][dst][91]} {frame_datapath_i/out[data][ip6][dst][92]} {frame_datapath_i/out[data][ip6][dst][93]} {frame_datapath_i/out[data][ip6][dst][94]} {frame_datapath_i/out[data][ip6][dst][95]} {frame_datapath_i/out[data][ip6][dst][96]} {frame_datapath_i/out[data][ip6][dst][97]} {frame_datapath_i/out[data][ip6][dst][98]} {frame_datapath_i/out[data][ip6][dst][99]} {frame_datapath_i/out[data][ip6][dst][100]} {frame_datapath_i/out[data][ip6][dst][101]} {frame_datapath_i/out[data][ip6][dst][102]} {frame_datapath_i/out[data][ip6][dst][103]} {frame_datapath_i/out[data][ip6][dst][104]} {frame_datapath_i/out[data][ip6][dst][105]} {frame_datapath_i/out[data][ip6][dst][106]} {frame_datapath_i/out[data][ip6][dst][107]} {frame_datapath_i/out[data][ip6][dst][108]} {frame_datapath_i/out[data][ip6][dst][109]} {frame_datapath_i/out[data][ip6][dst][110]} {frame_datapath_i/out[data][ip6][dst][111]} {frame_datapath_i/out[data][ip6][dst][112]} {frame_datapath_i/out[data][ip6][dst][113]} {frame_datapath_i/out[data][ip6][dst][114]} {frame_datapath_i/out[data][ip6][dst][115]} {frame_datapath_i/out[data][ip6][dst][116]} {frame_datapath_i/out[data][ip6][dst][117]} {frame_datapath_i/out[data][ip6][dst][118]} {frame_datapath_i/out[data][ip6][dst][119]} {frame_datapath_i/out[data][ip6][dst][120]} {frame_datapath_i/out[data][ip6][dst][121]} {frame_datapath_i/out[data][ip6][dst][122]} {frame_datapath_i/out[data][ip6][dst][123]} {frame_datapath_i/out[data][ip6][dst][124]} {frame_datapath_i/out[data][ip6][dst][125]} {frame_datapath_i/out[data][ip6][dst][126]} {frame_datapath_i/out[data][ip6][dst][127]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA [get_debug_ports u_ila_0/probe16]
set_property port_width 16 [get_debug_ports u_ila_0/probe16]
connect_debug_port u_ila_0/probe16 [get_nets [list {frame_datapath_i/in[data][ip6][payload_len][0]} {frame_datapath_i/in[data][ip6][payload_len][1]} {frame_datapath_i/in[data][ip6][payload_len][2]} {frame_datapath_i/in[data][ip6][payload_len][3]} {frame_datapath_i/in[data][ip6][payload_len][4]} {frame_datapath_i/in[data][ip6][payload_len][5]} {frame_datapath_i/in[data][ip6][payload_len][6]} {frame_datapath_i/in[data][ip6][payload_len][7]} {frame_datapath_i/in[data][ip6][payload_len][8]} {frame_datapath_i/in[data][ip6][payload_len][9]} {frame_datapath_i/in[data][ip6][payload_len][10]} {frame_datapath_i/in[data][ip6][payload_len][11]} {frame_datapath_i/in[data][ip6][payload_len][12]} {frame_datapath_i/in[data][ip6][payload_len][13]} {frame_datapath_i/in[data][ip6][payload_len][14]} {frame_datapath_i/in[data][ip6][payload_len][15]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA [get_debug_ports u_ila_0/probe17]
set_property port_width 16 [get_debug_ports u_ila_0/probe17]
connect_debug_port u_ila_0/probe17 [get_nets [list {frame_datapath_i/in[data][ip6][p][0]} {frame_datapath_i/in[data][ip6][p][1]} {frame_datapath_i/in[data][ip6][p][2]} {frame_datapath_i/in[data][ip6][p][3]} {frame_datapath_i/in[data][ip6][p][4]} {frame_datapath_i/in[data][ip6][p][5]} {frame_datapath_i/in[data][ip6][p][6]} {frame_datapath_i/in[data][ip6][p][7]} {frame_datapath_i/in[data][ip6][p][8]} {frame_datapath_i/in[data][ip6][p][9]} {frame_datapath_i/in[data][ip6][p][10]} {frame_datapath_i/in[data][ip6][p][11]} {frame_datapath_i/in[data][ip6][p][12]} {frame_datapath_i/in[data][ip6][p][13]} {frame_datapath_i/in[data][ip6][p][14]} {frame_datapath_i/in[data][ip6][p][15]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA [get_debug_ports u_ila_0/probe18]
set_property port_width 8 [get_debug_ports u_ila_0/probe18]
connect_debug_port u_ila_0/probe18 [get_nets [list {frame_datapath_i/out[data][ip6][next_hdr][0]} {frame_datapath_i/out[data][ip6][next_hdr][1]} {frame_datapath_i/out[data][ip6][next_hdr][2]} {frame_datapath_i/out[data][ip6][next_hdr][3]} {frame_datapath_i/out[data][ip6][next_hdr][4]} {frame_datapath_i/out[data][ip6][next_hdr][5]} {frame_datapath_i/out[data][ip6][next_hdr][6]} {frame_datapath_i/out[data][ip6][next_hdr][7]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA [get_debug_ports u_ila_0/probe19]
set_property port_width 4 [get_debug_ports u_ila_0/probe19]
connect_debug_port u_ila_0/probe19 [get_nets [list {frame_datapath_i/out[data][ip6][flow_hi][0]} {frame_datapath_i/out[data][ip6][flow_hi][1]} {frame_datapath_i/out[data][ip6][flow_hi][2]} {frame_datapath_i/out[data][ip6][flow_hi][3]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA [get_debug_ports u_ila_0/probe20]
set_property port_width 16 [get_debug_ports u_ila_0/probe20]
connect_debug_port u_ila_0/probe20 [get_nets [list {frame_datapath_i/out[data][ip6][payload_len][0]} {frame_datapath_i/out[data][ip6][payload_len][1]} {frame_datapath_i/out[data][ip6][payload_len][2]} {frame_datapath_i/out[data][ip6][payload_len][3]} {frame_datapath_i/out[data][ip6][payload_len][4]} {frame_datapath_i/out[data][ip6][payload_len][5]} {frame_datapath_i/out[data][ip6][payload_len][6]} {frame_datapath_i/out[data][ip6][payload_len][7]} {frame_datapath_i/out[data][ip6][payload_len][8]} {frame_datapath_i/out[data][ip6][payload_len][9]} {frame_datapath_i/out[data][ip6][payload_len][10]} {frame_datapath_i/out[data][ip6][payload_len][11]} {frame_datapath_i/out[data][ip6][payload_len][12]} {frame_datapath_i/out[data][ip6][payload_len][13]} {frame_datapath_i/out[data][ip6][payload_len][14]} {frame_datapath_i/out[data][ip6][payload_len][15]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA [get_debug_ports u_ila_0/probe21]
set_property port_width 2 [get_debug_ports u_ila_0/probe21]
connect_debug_port u_ila_0/probe21 [get_nets [list {frame_datapath_i/out[meta][dest][0]} {frame_datapath_i/out[meta][dest][1]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA [get_debug_ports u_ila_0/probe22]
set_property port_width 24 [get_debug_ports u_ila_0/probe22]
connect_debug_port u_ila_0/probe22 [get_nets [list {frame_datapath_i/out[data][ip6][flow_lo][0]} {frame_datapath_i/out[data][ip6][flow_lo][1]} {frame_datapath_i/out[data][ip6][flow_lo][2]} {frame_datapath_i/out[data][ip6][flow_lo][3]} {frame_datapath_i/out[data][ip6][flow_lo][4]} {frame_datapath_i/out[data][ip6][flow_lo][5]} {frame_datapath_i/out[data][ip6][flow_lo][6]} {frame_datapath_i/out[data][ip6][flow_lo][7]} {frame_datapath_i/out[data][ip6][flow_lo][8]} {frame_datapath_i/out[data][ip6][flow_lo][9]} {frame_datapath_i/out[data][ip6][flow_lo][10]} {frame_datapath_i/out[data][ip6][flow_lo][11]} {frame_datapath_i/out[data][ip6][flow_lo][12]} {frame_datapath_i/out[data][ip6][flow_lo][13]} {frame_datapath_i/out[data][ip6][flow_lo][14]} {frame_datapath_i/out[data][ip6][flow_lo][15]} {frame_datapath_i/out[data][ip6][flow_lo][16]} {frame_datapath_i/out[data][ip6][flow_lo][17]} {frame_datapath_i/out[data][ip6][flow_lo][18]} {frame_datapath_i/out[data][ip6][flow_lo][19]} {frame_datapath_i/out[data][ip6][flow_lo][20]} {frame_datapath_i/out[data][ip6][flow_lo][21]} {frame_datapath_i/out[data][ip6][flow_lo][22]} {frame_datapath_i/out[data][ip6][flow_lo][23]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA [get_debug_ports u_ila_0/probe23]
set_property port_width 8 [get_debug_ports u_ila_0/probe23]
connect_debug_port u_ila_0/probe23 [get_nets [list {frame_datapath_i/out[data][ip6][hop_limit][0]} {frame_datapath_i/out[data][ip6][hop_limit][1]} {frame_datapath_i/out[data][ip6][hop_limit][2]} {frame_datapath_i/out[data][ip6][hop_limit][3]} {frame_datapath_i/out[data][ip6][hop_limit][4]} {frame_datapath_i/out[data][ip6][hop_limit][5]} {frame_datapath_i/out[data][ip6][hop_limit][6]} {frame_datapath_i/out[data][ip6][hop_limit][7]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA [get_debug_ports u_ila_0/probe24]
set_property port_width 48 [get_debug_ports u_ila_0/probe24]
connect_debug_port u_ila_0/probe24 [get_nets [list {frame_datapath_i/out[data][src][0]} {frame_datapath_i/out[data][src][1]} {frame_datapath_i/out[data][src][2]} {frame_datapath_i/out[data][src][3]} {frame_datapath_i/out[data][src][4]} {frame_datapath_i/out[data][src][5]} {frame_datapath_i/out[data][src][6]} {frame_datapath_i/out[data][src][7]} {frame_datapath_i/out[data][src][8]} {frame_datapath_i/out[data][src][9]} {frame_datapath_i/out[data][src][10]} {frame_datapath_i/out[data][src][11]} {frame_datapath_i/out[data][src][12]} {frame_datapath_i/out[data][src][13]} {frame_datapath_i/out[data][src][14]} {frame_datapath_i/out[data][src][15]} {frame_datapath_i/out[data][src][16]} {frame_datapath_i/out[data][src][17]} {frame_datapath_i/out[data][src][18]} {frame_datapath_i/out[data][src][19]} {frame_datapath_i/out[data][src][20]} {frame_datapath_i/out[data][src][21]} {frame_datapath_i/out[data][src][22]} {frame_datapath_i/out[data][src][23]} {frame_datapath_i/out[data][src][24]} {frame_datapath_i/out[data][src][25]} {frame_datapath_i/out[data][src][26]} {frame_datapath_i/out[data][src][27]} {frame_datapath_i/out[data][src][28]} {frame_datapath_i/out[data][src][29]} {frame_datapath_i/out[data][src][30]} {frame_datapath_i/out[data][src][31]} {frame_datapath_i/out[data][src][32]} {frame_datapath_i/out[data][src][33]} {frame_datapath_i/out[data][src][34]} {frame_datapath_i/out[data][src][35]} {frame_datapath_i/out[data][src][36]} {frame_datapath_i/out[data][src][37]} {frame_datapath_i/out[data][src][38]} {frame_datapath_i/out[data][src][39]} {frame_datapath_i/out[data][src][40]} {frame_datapath_i/out[data][src][41]} {frame_datapath_i/out[data][src][42]} {frame_datapath_i/out[data][src][43]} {frame_datapath_i/out[data][src][44]} {frame_datapath_i/out[data][src][45]} {frame_datapath_i/out[data][src][46]} {frame_datapath_i/out[data][src][47]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA [get_debug_ports u_ila_0/probe25]
set_property port_width 4 [get_debug_ports u_ila_0/probe25]
connect_debug_port u_ila_0/probe25 [get_nets [list {frame_datapath_i/out[data][ip6][version][0]} {frame_datapath_i/out[data][ip6][version][1]} {frame_datapath_i/out[data][ip6][version][2]} {frame_datapath_i/out[data][ip6][version][3]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA [get_debug_ports u_ila_0/probe26]
set_property port_width 128 [get_debug_ports u_ila_0/probe26]
connect_debug_port u_ila_0/probe26 [get_nets [list {frame_datapath_i/out[data][ip6][src][0]} {frame_datapath_i/out[data][ip6][src][1]} {frame_datapath_i/out[data][ip6][src][2]} {frame_datapath_i/out[data][ip6][src][3]} {frame_datapath_i/out[data][ip6][src][4]} {frame_datapath_i/out[data][ip6][src][5]} {frame_datapath_i/out[data][ip6][src][6]} {frame_datapath_i/out[data][ip6][src][7]} {frame_datapath_i/out[data][ip6][src][8]} {frame_datapath_i/out[data][ip6][src][9]} {frame_datapath_i/out[data][ip6][src][10]} {frame_datapath_i/out[data][ip6][src][11]} {frame_datapath_i/out[data][ip6][src][12]} {frame_datapath_i/out[data][ip6][src][13]} {frame_datapath_i/out[data][ip6][src][14]} {frame_datapath_i/out[data][ip6][src][15]} {frame_datapath_i/out[data][ip6][src][16]} {frame_datapath_i/out[data][ip6][src][17]} {frame_datapath_i/out[data][ip6][src][18]} {frame_datapath_i/out[data][ip6][src][19]} {frame_datapath_i/out[data][ip6][src][20]} {frame_datapath_i/out[data][ip6][src][21]} {frame_datapath_i/out[data][ip6][src][22]} {frame_datapath_i/out[data][ip6][src][23]} {frame_datapath_i/out[data][ip6][src][24]} {frame_datapath_i/out[data][ip6][src][25]} {frame_datapath_i/out[data][ip6][src][26]} {frame_datapath_i/out[data][ip6][src][27]} {frame_datapath_i/out[data][ip6][src][28]} {frame_datapath_i/out[data][ip6][src][29]} {frame_datapath_i/out[data][ip6][src][30]} {frame_datapath_i/out[data][ip6][src][31]} {frame_datapath_i/out[data][ip6][src][32]} {frame_datapath_i/out[data][ip6][src][33]} {frame_datapath_i/out[data][ip6][src][34]} {frame_datapath_i/out[data][ip6][src][35]} {frame_datapath_i/out[data][ip6][src][36]} {frame_datapath_i/out[data][ip6][src][37]} {frame_datapath_i/out[data][ip6][src][38]} {frame_datapath_i/out[data][ip6][src][39]} {frame_datapath_i/out[data][ip6][src][40]} {frame_datapath_i/out[data][ip6][src][41]} {frame_datapath_i/out[data][ip6][src][42]} {frame_datapath_i/out[data][ip6][src][43]} {frame_datapath_i/out[data][ip6][src][44]} {frame_datapath_i/out[data][ip6][src][45]} {frame_datapath_i/out[data][ip6][src][46]} {frame_datapath_i/out[data][ip6][src][47]} {frame_datapath_i/out[data][ip6][src][48]} {frame_datapath_i/out[data][ip6][src][49]} {frame_datapath_i/out[data][ip6][src][50]} {frame_datapath_i/out[data][ip6][src][51]} {frame_datapath_i/out[data][ip6][src][52]} {frame_datapath_i/out[data][ip6][src][53]} {frame_datapath_i/out[data][ip6][src][54]} {frame_datapath_i/out[data][ip6][src][55]} {frame_datapath_i/out[data][ip6][src][56]} {frame_datapath_i/out[data][ip6][src][57]} {frame_datapath_i/out[data][ip6][src][58]} {frame_datapath_i/out[data][ip6][src][59]} {frame_datapath_i/out[data][ip6][src][60]} {frame_datapath_i/out[data][ip6][src][61]} {frame_datapath_i/out[data][ip6][src][62]} {frame_datapath_i/out[data][ip6][src][63]} {frame_datapath_i/out[data][ip6][src][64]} {frame_datapath_i/out[data][ip6][src][65]} {frame_datapath_i/out[data][ip6][src][66]} {frame_datapath_i/out[data][ip6][src][67]} {frame_datapath_i/out[data][ip6][src][68]} {frame_datapath_i/out[data][ip6][src][69]} {frame_datapath_i/out[data][ip6][src][70]} {frame_datapath_i/out[data][ip6][src][71]} {frame_datapath_i/out[data][ip6][src][72]} {frame_datapath_i/out[data][ip6][src][73]} {frame_datapath_i/out[data][ip6][src][74]} {frame_datapath_i/out[data][ip6][src][75]} {frame_datapath_i/out[data][ip6][src][76]} {frame_datapath_i/out[data][ip6][src][77]} {frame_datapath_i/out[data][ip6][src][78]} {frame_datapath_i/out[data][ip6][src][79]} {frame_datapath_i/out[data][ip6][src][80]} {frame_datapath_i/out[data][ip6][src][81]} {frame_datapath_i/out[data][ip6][src][82]} {frame_datapath_i/out[data][ip6][src][83]} {frame_datapath_i/out[data][ip6][src][84]} {frame_datapath_i/out[data][ip6][src][85]} {frame_datapath_i/out[data][ip6][src][86]} {frame_datapath_i/out[data][ip6][src][87]} {frame_datapath_i/out[data][ip6][src][88]} {frame_datapath_i/out[data][ip6][src][89]} {frame_datapath_i/out[data][ip6][src][90]} {frame_datapath_i/out[data][ip6][src][91]} {frame_datapath_i/out[data][ip6][src][92]} {frame_datapath_i/out[data][ip6][src][93]} {frame_datapath_i/out[data][ip6][src][94]} {frame_datapath_i/out[data][ip6][src][95]} {frame_datapath_i/out[data][ip6][src][96]} {frame_datapath_i/out[data][ip6][src][97]} {frame_datapath_i/out[data][ip6][src][98]} {frame_datapath_i/out[data][ip6][src][99]} {frame_datapath_i/out[data][ip6][src][100]} {frame_datapath_i/out[data][ip6][src][101]} {frame_datapath_i/out[data][ip6][src][102]} {frame_datapath_i/out[data][ip6][src][103]} {frame_datapath_i/out[data][ip6][src][104]} {frame_datapath_i/out[data][ip6][src][105]} {frame_datapath_i/out[data][ip6][src][106]} {frame_datapath_i/out[data][ip6][src][107]} {frame_datapath_i/out[data][ip6][src][108]} {frame_datapath_i/out[data][ip6][src][109]} {frame_datapath_i/out[data][ip6][src][110]} {frame_datapath_i/out[data][ip6][src][111]} {frame_datapath_i/out[data][ip6][src][112]} {frame_datapath_i/out[data][ip6][src][113]} {frame_datapath_i/out[data][ip6][src][114]} {frame_datapath_i/out[data][ip6][src][115]} {frame_datapath_i/out[data][ip6][src][116]} {frame_datapath_i/out[data][ip6][src][117]} {frame_datapath_i/out[data][ip6][src][118]} {frame_datapath_i/out[data][ip6][src][119]} {frame_datapath_i/out[data][ip6][src][120]} {frame_datapath_i/out[data][ip6][src][121]} {frame_datapath_i/out[data][ip6][src][122]} {frame_datapath_i/out[data][ip6][src][123]} {frame_datapath_i/out[data][ip6][src][124]} {frame_datapath_i/out[data][ip6][src][125]} {frame_datapath_i/out[data][ip6][src][126]} {frame_datapath_i/out[data][ip6][src][127]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe27]
set_property port_width 1 [get_debug_ports u_ila_0/probe27]
connect_debug_port u_ila_0/probe27 [get_nets [list frame_datapath_i/fw_in_valid]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe28]
set_property port_width 1 [get_debug_ports u_ila_0/probe28]
connect_debug_port u_ila_0/probe28 [get_nets [list frame_datapath_i/fw_out_ready]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe29]
set_property port_width 1 [get_debug_ports u_ila_0/probe29]
connect_debug_port u_ila_0/probe29 [get_nets [list frame_datapath_i/handling_fw]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe30]
set_property port_width 1 [get_debug_ports u_ila_0/probe30]
connect_debug_port u_ila_0/probe30 [get_nets [list frame_datapath_i/handling_na]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe31]
set_property port_width 1 [get_debug_ports u_ila_0/probe31]
connect_debug_port u_ila_0/probe31 [get_nets [list frame_datapath_i/handling_ns]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA [get_debug_ports u_ila_0/probe32]
set_property port_width 1 [get_debug_ports u_ila_0/probe32]
connect_debug_port u_ila_0/probe32 [get_nets [list {frame_datapath_i/in[is_first]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA [get_debug_ports u_ila_0/probe33]
set_property port_width 1 [get_debug_ports u_ila_0/probe33]
connect_debug_port u_ila_0/probe33 [get_nets [list {frame_datapath_i/in[last]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe34]
set_property port_width 1 [get_debug_ports u_ila_0/probe34]
connect_debug_port u_ila_0/probe34 [get_nets [list {frame_datapath_i/in[valid]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe35]
set_property port_width 1 [get_debug_ports u_ila_0/probe35]
connect_debug_port u_ila_0/probe35 [get_nets [list frame_datapath_i/in_ready]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe36]
set_property port_width 1 [get_debug_ports u_ila_0/probe36]
connect_debug_port u_ila_0/probe36 [get_nets [list frame_datapath_i/na_in_valid]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe37]
set_property port_width 1 [get_debug_ports u_ila_0/probe37]
connect_debug_port u_ila_0/probe37 [get_nets [list frame_datapath_i/ns_in_valid]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe38]
set_property port_width 1 [get_debug_ports u_ila_0/probe38]
connect_debug_port u_ila_0/probe38 [get_nets [list frame_datapath_i/ns_out_ready]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe39]
set_property port_width 1 [get_debug_ports u_ila_0/probe39]
connect_debug_port u_ila_0/probe39 [get_nets [list frame_datapath_i/nud_out_ready]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA [get_debug_ports u_ila_0/probe40]
set_property port_width 1 [get_debug_ports u_ila_0/probe40]
connect_debug_port u_ila_0/probe40 [get_nets [list {frame_datapath_i/out[last]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe41]
set_property port_width 1 [get_debug_ports u_ila_0/probe41]
connect_debug_port u_ila_0/probe41 [get_nets [list {frame_datapath_i/out[valid]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA [get_debug_ports u_ila_0/probe42]
set_property port_width 1 [get_debug_ports u_ila_0/probe42]
connect_debug_port u_ila_0/probe42 [get_nets [list frame_datapath_i/out_is_first]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe43]
set_property port_width 1 [get_debug_ports u_ila_0/probe43]
connect_debug_port u_ila_0/probe43 [get_nets [list frame_datapath_i/out_ready]]
set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets eth_clk]
