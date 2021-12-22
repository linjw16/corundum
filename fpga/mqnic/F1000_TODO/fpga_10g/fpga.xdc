# XDC constraints for the Resnet F1000 board
# part: zu19eg-ffvc1760-2-e

# General configuration
# set_property CFGBVS GND									[current_design]
# set_property CONFIG_VOLTAGE 1.8							[current_design]
set_property BITSTREAM.GENERAL.COMPRESS true				[current_design]
# set_property BITSTREAM.CONFIG.EXTMASTERCCLK_EN disable 	[current_design]
# set_property BITSTREAM.CONFIG.SPI_32BIT_ADDR YES			[current_design]
# set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4				[current_design]
# set_property BITSTREAM.CONFIG.SPI_FALL_EDGE YES			[current_design]
# set_property BITSTREAM.CONFIG.CONFIGRATE 85.0				[current_design]
# set_property CONFIG_MODE SPIx4							[current_design]
# set_property BITSTREAM.CONFIG.OVERTEMPSHUTDOWN Enable		[current_design]

# System clocks
# reference clock from QSFP, 25 MHz
# set_property -dict {LOC B32 IOSTANDARD DIFF_SSTL12} [get_ports clk_ref_p]
# set_property -dict {LOC B33 IOSTANDARD DIFF_SSTL12} [get_ports clk_ref_n]
# create_clock -period 40.000 -name clk_ref_25mhz [get_ports clk_ref_p]

# 25 MHz
# set_property -dict {LOC AU21 IOSTANDARD DIFF_SSTL12} [get_ports clk_25mhz_p]
# set_property -dict {LOC AV21 IOSTANDARD DIFF_SSTL12} [get_ports clk_25mhz_n]
# create_clock -period 40.000 -name clk_25mhz [get_ports clk_25mhz_p]

# 100 MHz
set_property -dict {LOC G17 IOSTANDARD DIFF_SSTL12} [get_ports clk_100mhz_p]
set_property -dict {LOC F17 IOSTANDARD DIFF_SSTL12} [get_ports clk_100mhz_n]
create_clock -period 10.000 -name clk_100mhz [get_ports clk_100mhz_p]

# E7 is not a global clock capable input, so need to set CLOCK_DEDICATED_ROUTE to satisfy DRC
# set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets init_clk_ibuf_inst/O]
set_property CLOCK_DEDICATED_ROUTE ANY_CMT_COLUMN [get_nets clk_100mhz_ibufg]

# DDR4 refclk1
#set_property -dict {LOC AT32 IOSTANDARD DIFF_SSTL12} [get_ports clk_ddr4_refclk1_p]
#set_property -dict {LOC AU32 IOSTANDARD DIFF_SSTL12} [get_ports clk_ddr4_refclk1_n]
#create_clock -period 3.750 -name clk_ddr4_refclk1 [get_ports clk_ddr4_refclk1_p]

# DDR4 refclk2
#set_property -dict {LOC G29  IOSTANDARD DIFF_SSTL12} [get_ports clk_ddr4_refclk2_p]
#set_property -dict {LOC G28  IOSTANDARD DIFF_SSTL12} [get_ports clk_ddr4_refclk2_n]
#create_clock -period 3.750 -name clk_ddr4_refclk2 [get_ports clk_ddr4_refclk1_p]

# LEDs: J11 H10 H11 G11 H13 G12 H14 G13
set_property -dict {LOC J11 IOSTANDARD LVCMOS12 SLEW SLOW DRIVE 8} [get_ports led_sreg_d]
set_property -dict {LOC H10 IOSTANDARD LVCMOS12 SLEW SLOW DRIVE 8} [get_ports led_sreg_ld]
set_property -dict {LOC H11 IOSTANDARD LVCMOS12 SLEW SLOW DRIVE 8} [get_ports led_sreg_clk]
set_property -dict {LOC G11 IOSTANDARD LVCMOS12 SLEW SLOW DRIVE 8} [get_ports {led_bmc[0]}]
set_property -dict {LOC H13 IOSTANDARD LVCMOS12 SLEW SLOW DRIVE 8} [get_ports {led_bmc[1]}]
set_property -dict {LOC G12 IOSTANDARD LVCMOS12 SLEW SLOW DRIVE 8} [get_ports {led_exp[0]}]
set_property -dict {LOC H14 IOSTANDARD LVCMOS12 SLEW SLOW DRIVE 8} [get_ports {led_exp[1]}]
# set_property -dict {LOC G13 IOSTANDARD LVCMOS12 SLEW SLOW DRIVE 8} [get_ports {led[7]}]

set_false_path -to [get_ports {led_sreg_d led_sreg_ld led_sreg_clk led_bmc[*] led_exp[*]}]
set_output_delay 0 [get_ports {led_sreg_d led_sreg_ld led_sreg_clk led_bmc[*] led_exp[*]}]

# DIP switches
# set_property -dict {LOC AW9 IOSTANDARD LVCMOS12} [get_ports {sw[0]}]
# set_property -dict {LOC AY9 IOSTANDARD LVCMOS12} [get_ports {sw[1]}]
# set_property -dict {LOC BB9 IOSTANDARD LVCMOS12} [get_ports {sw[2]}]
# set_property -dict {LOC BB8 IOSTANDARD LVCMOS12} [get_ports {sw[3]}]
# set_false_path -from [get_ports {sw[*]}]
# set_input_delay 0 [get_ports {sw[*]}]

# GPIO
# set_property -dict {LOC B4 IOSTANDARD LVCMOS33} [get_ports pps_in] ;# from SMA J6 via Q1 (inverted)
# set_property -dict {LOC A4 IOSTANDARD LVCMOS33 SLEW FAST DRIVE 4} [get_ports pps_out] ;# to SMA J6 via U4 and U5, and u.FL J7 (PPS OUT) via U3
# set_property -dict {LOC A3 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 4} [get_ports pps_out_en] ; # to U5 IN (connects pps_out to SMA J6 when high)
# #set_property -dict {LOC H2 IOSTANDARD LVCMOS33} [get_ports misc_ucoax] ; from u.FL J5 (PPS IN)

# set_false_path -to [get_ports {pps_out pps_out_en}]
# set_output_delay 0 [get_ports {pps_out pps_out_en}]
# set_false_path -from [get_ports {pps_in}]
# set_input_delay 0 [get_ports {pps_in}]

# # BMC interface
# set_property -dict {LOC B6 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 4} [get_ports bmc_clk]
# set_property -dict {LOC J4 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 4} [get_ports bmc_nss]
# set_property -dict {LOC D5 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 4} [get_ports bmc_mosi]
# set_property -dict {LOC D7 IOSTANDARD LVCMOS18} [get_ports bmc_miso]
# set_property -dict {LOC H4 IOSTANDARD LVCMOS18} [get_ports bmc_int]

# set_false_path -to [get_ports {bmc_clk bmc_nss bmc_mosi}]
# set_output_delay 0 [get_ports {bmc_clk bmc_nss bmc_mosi}]
# set_false_path -from [get_ports {bmc_miso bmc_int}]
# set_input_delay 0 [get_ports {bmc_miso bmc_int}]

# # Board status
# #set_property -dict {LOC J2 IOSTANDARD LVCMOS33} [get_ports {fan_tacho[0]}]
# #set_property -dict {LOC J3 IOSTANDARD LVCMOS33} [get_ports {fan_tacho[1]}]
# set_property -dict {LOC A6 IOSTANDARD LVCMOS18} [get_ports {pg[0]}]
# set_property -dict {LOC C7 IOSTANDARD LVCMOS18} [get_ports {pg[1]}]
# #set_property -dict {LOC E2 IOSTANDARD LVCMOS33} [get_ports pwrbrk]

# set_false_path -from [get_ports {pg[*]}]
# set_input_delay 0 [get_ports {pg[*]}]

# QSFP28 Interfaces
set_property -dict {LOC H39 } [get_ports qsfp_0_rx_3_p] ;# MGTYRXP0_130 GTYE4_CHANNEL_X0Y12 / GTYE4_COMMON_X0Y1
set_property -dict {LOC H40 } [get_ports qsfp_0_rx_3_n] ;# MGTYRXN0_130 GTYE4_CHANNEL_X0Y12 / GTYE4_COMMON_X0Y1
set_property -dict {LOC J36 } [get_ports qsfp_0_tx_3_p] ;# MGTYTXP0_130 GTYE4_CHANNEL_X0Y12 / GTYE4_COMMON_X0Y1
set_property -dict {LOC J37 } [get_ports qsfp_0_tx_3_n] ;# MGTYTXN0_130 GTYE4_CHANNEL_X0Y12 / GTYE4_COMMON_X0Y1
set_property -dict {LOC J41 } [get_ports qsfp_0_rx_2_p] ;# MGTYRXP1_130 GTYE4_CHANNEL_X0Y13 / GTYE4_COMMON_X0Y1
set_property -dict {LOC J42 } [get_ports qsfp_0_rx_2_n] ;# MGTYRXN1_130 GTYE4_CHANNEL_X0Y13 / GTYE4_COMMON_X0Y1
set_property -dict {LOC K34 } [get_ports qsfp_0_tx_2_p] ;# MGTYTXP1_130 GTYE4_CHANNEL_X0Y13 / GTYE4_COMMON_X0Y1
set_property -dict {LOC K35 } [get_ports qsfp_0_tx_2_n] ;# MGTYTXN1_130 GTYE4_CHANNEL_X0Y13 / GTYE4_COMMON_X0Y1
set_property -dict {LOC K39 } [get_ports qsfp_0_rx_1_p] ;# MGTYRXP2_130 GTYE4_CHANNEL_X0Y14 / GTYE4_COMMON_X0Y1
set_property -dict {LOC K40 } [get_ports qsfp_0_rx_1_n] ;# MGTYRXN2_130 GTYE4_CHANNEL_X0Y14 / GTYE4_COMMON_X0Y1
set_property -dict {LOC L36 } [get_ports qsfp_0_tx_1_p] ;# MGTYTXP2_130 GTYE4_CHANNEL_X0Y14 / GTYE4_COMMON_X0Y1
set_property -dict {LOC L37 } [get_ports qsfp_0_tx_1_n] ;# MGTYTXN2_130 GTYE4_CHANNEL_X0Y14 / GTYE4_COMMON_X0Y1
set_property -dict {LOC L41 } [get_ports qsfp_0_rx_0_p] ;# MGTYRXP3_130 GTYE4_CHANNEL_X0Y15 / GTYE4_COMMON_X0Y1
set_property -dict {LOC L42 } [get_ports qsfp_0_rx_0_n] ;# MGTYRXN3_130 GTYE4_CHANNEL_X0Y15 / GTYE4_COMMON_X0Y1
set_property -dict {LOC M34 } [get_ports qsfp_0_tx_0_p] ;# MGTYTXP3_130 GTYE4_CHANNEL_X0Y15 / GTYE4_COMMON_X0Y1
set_property -dict {LOC M35 } [get_ports qsfp_0_tx_0_n] ;# MGTYTXN3_130 GTYE4_CHANNEL_X0Y15 / GTYE4_COMMON_X0Y1
set_property -dict {LOC R32 } [get_ports qsfp_0_mgt_refclk_p] ;# MGTREFCLK0P_130 from SI5394 OUT0
set_property -dict {LOC R33 } [get_ports qsfp_0_mgt_refclk_n] ;# MGTREFCLK0N_130 from SI5394 OUT0

set_property -dict {LOC G6 IOSTANDARD LVCMOS18 PULLUP true} [get_ports qsfp_0_mod_prsnt_n]
set_property -dict {LOC H8 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 4} [get_ports qsfp_0_reset_n]
set_property -dict {LOC J9 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 4} [get_ports qsfp_0_lp_mode]
set_property -dict {LOC F6 IOSTANDARD LVCMOS18 PULLUP true} [get_ports qsfp_0_intr_n]

set_false_path -to [get_ports {qsfp_0_reset_n qsfp_0_lp_mode}]
set_output_delay 0 [get_ports {qsfp_0_reset_n qsfp_0_lp_mode}]
set_false_path -from [get_ports {qsfp_0_mod_prsnt_n qsfp_0_intr_n}]
set_input_delay 0 [get_ports {qsfp_0_mod_prsnt_n qsfp_0_intr_n}]

# set_property -dict {LOC B12 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 4} [get_ports qsfp_0_i2c_scl]
# set_property -dict {LOC B11 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 4} [get_ports qsfp_0_i2c_sda]

# 322.265625 MHz MGT reference clock
create_clock -period 3.103 -name qsfp_0_mgt_refclk [get_ports qsfp_0_mgt_refclk_p]


# set_false_path -to [get_ports {qsfp_0_i2c_scl qsfp_0_i2c_sda}]
# set_output_delay 0 [get_ports {qsfp_0_i2c_scl qsfp_0_i2c_sda}]
# set_false_path -from [get_ports {qsfp_0_i2c_scl qsfp_0_i2c_sda}]
# set_input_delay 0 [get_ports {qsfp_0_i2c_scl qsfp_0_i2c_sda}]

set_property -dict {LOC D39 } [get_ports qsfp_1_rx_3_p] ;# MGTYRXP0_131 GTYE4_CHANNEL_X0Y16 / GTYE4_COMMON_X0Y2
set_property -dict {LOC D40 } [get_ports qsfp_1_rx_3_n] ;# MGTYRXP0_131 GTYE4_CHANNEL_X0Y16 / GTYE4_COMMON_X0Y2
set_property -dict {LOC E36 } [get_ports qsfp_1_tx_3_p] ;# MGTYRXP0_131 GTYE4_CHANNEL_X0Y16 / GTYE4_COMMON_X0Y2
set_property -dict {LOC E37 } [get_ports qsfp_1_tx_3_n] ;# MGTYTXN0_131 GTYE4_CHANNEL_X0Y16 / GTYE4_COMMON_X0Y2
set_property -dict {LOC E41 } [get_ports qsfp_1_rx_2_p] ;# MGTYRXP1_131 GTYE4_CHANNEL_X0Y17 / GTYE4_COMMON_X0Y2
set_property -dict {LOC E42 } [get_ports qsfp_1_rx_2_n] ;# MGTYRXN1_131 GTYE4_CHANNEL_X0Y17 / GTYE4_COMMON_X0Y2
set_property -dict {LOC F34 } [get_ports qsfp_1_tx_2_p] ;# MGTYTXP1_131 GTYE4_CHANNEL_X0Y17 / GTYE4_COMMON_X0Y2
set_property -dict {LOC F35 } [get_ports qsfp_1_tx_2_n] ;# MGTYRXP0_131 GTYE4_CHANNEL_X0Y17 / GTYE4_COMMON_X0Y2
set_property -dict {LOC F39 } [get_ports qsfp_1_rx_1_p] ;# MGTYRXP0_131 GTYE4_CHANNEL_X0Y18 / GTYE4_COMMON_X0Y2
set_property -dict {LOC F40 } [get_ports qsfp_1_rx_1_n] ;# MGTYRXP0_131 GTYE4_CHANNEL_X0Y18 / GTYE4_COMMON_X0Y2
set_property -dict {LOC G36 } [get_ports qsfp_1_tx_1_p] ;# MGTYRXP0_131 GTYE4_CHANNEL_X0Y18 / GTYE4_COMMON_X0Y2
set_property -dict {LOC G37 } [get_ports qsfp_1_tx_1_n] ;# MGTYRXP0_131 GTYE4_CHANNEL_X0Y18 / GTYE4_COMMON_X0Y2
set_property -dict {LOC G41 } [get_ports qsfp_1_rx_0_p] ;# MGTYRXP0_131 GTYE4_CHANNEL_X0Y19 / GTYE4_COMMON_X0Y2
set_property -dict {LOC G42 } [get_ports qsfp_1_rx_0_n] ;# MGTYRXP0_131 GTYE4_CHANNEL_X0Y19 / GTYE4_COMMON_X0Y2
set_property -dict {LOC H34 } [get_ports qsfp_1_tx_0_p] ;# MGTYRXP0_131 GTYE4_CHANNEL_X0Y19 / GTYE4_COMMON_X0Y2
set_property -dict {LOC H35 } [get_ports qsfp_1_tx_0_n] ;# MGTYRXP0_131 GTYE4_CHANNEL_X0Y19 / GTYE4_COMMON_X0Y2

set_property -dict {LOC L32 } [get_ports qsfp_1_mgt_refclk_p] ;# MGTREFCLK1P_230 from U12.18
set_property -dict {LOC L33 } [get_ports qsfp_1_mgt_refclk_n] ;# MGTREFCLK1N_230 from U12.17

# 322.265625 MHz MGT reference clock
create_clock -period 3.103 -name qsfp_1_mgt_refclk [get_ports qsfp_1_mgt_refclk_p]

set_property -dict {LOC F9 IOSTANDARD LVCMOS18 PULLUP true} [get_ports qsfp_1_mod_prsnt_n]
set_property -dict {LOC F7 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 4} [get_ports qsfp_1_reset_n]
set_property -dict {LOC G8 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 4} [get_ports qsfp_1_lp_mode]
set_property -dict {LOC E9 IOSTANDARD LVCMOS18 PULLUP true} [get_ports qsfp_1_intr_n]

set_false_path -to [get_ports {qsfp_1_reset_n qsfp_1_lp_mode}]
set_output_delay 0 [get_ports {qsfp_1_reset_n qsfp_1_lp_mode}]
set_false_path -from [get_ports {qsfp_1_mod_prsnt_n qsfp_1_intr_n}]
set_input_delay 0 [get_ports {qsfp_1_mod_prsnt_n qsfp_1_intr_n}]

# set_property -dict {LOC G11 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 4} [get_ports qsfp_1_i2c_scl]
# set_property -dict {LOC H11 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 4} [get_ports qsfp_1_i2c_sda]

# set_false_path -to [get_ports {qsfp_1_i2c_scl qsfp_1_i2c_sda}]
# set_output_delay 0 [get_ports {qsfp_1_i2c_scl qsfp_1_i2c_sda}]
# set_false_path -from [get_ports {qsfp_1_i2c_scl qsfp_1_i2c_sda}]
# set_input_delay 0 [get_ports {qsfp_1_i2c_scl qsfp_1_i2c_sda}]

# PCIe Interface
set_property PACKAGE_PIN AE1 [get_ports pcie_rx_n[0] ] 
set_property PACKAGE_PIN AF3 [get_ports pcie_rx_n[1] ] 
set_property PACKAGE_PIN AR1 [get_ports pcie_rx_n[10]] 
set_property PACKAGE_PIN AT3 [get_ports pcie_rx_n[11]] 
set_property PACKAGE_PIN AU1 [get_ports pcie_rx_n[12]] 
set_property PACKAGE_PIN AV3 [get_ports pcie_rx_n[13]] 
set_property PACKAGE_PIN AW1 [get_ports pcie_rx_n[14]] 
set_property PACKAGE_PIN BA1 [get_ports pcie_rx_n[15]] 
set_property PACKAGE_PIN AG1 [get_ports pcie_rx_n[2] ] 
set_property PACKAGE_PIN AH3 [get_ports pcie_rx_n[3] ] 
set_property PACKAGE_PIN AJ1 [get_ports pcie_rx_n[4] ] 
set_property PACKAGE_PIN AK3 [get_ports pcie_rx_n[5] ] 
set_property PACKAGE_PIN AL1 [get_ports pcie_rx_n[6] ] 
set_property PACKAGE_PIN AM3 [get_ports pcie_rx_n[7] ] 
set_property PACKAGE_PIN AN1 [get_ports pcie_rx_n[8] ] 
set_property PACKAGE_PIN AP3 [get_ports pcie_rx_n[9] ] 
set_property PACKAGE_PIN AE2 [get_ports pcie_rx_p[0] ] 
set_property PACKAGE_PIN AF4 [get_ports pcie_rx_p[1] ] 
set_property PACKAGE_PIN AR2 [get_ports pcie_rx_p[10]] 
set_property PACKAGE_PIN AT4 [get_ports pcie_rx_p[11]] 
set_property PACKAGE_PIN AU2 [get_ports pcie_rx_p[12]] 
set_property PACKAGE_PIN AV4 [get_ports pcie_rx_p[13]] 
set_property PACKAGE_PIN AW2 [get_ports pcie_rx_p[14]] 
set_property PACKAGE_PIN BA2 [get_ports pcie_rx_p[15]] 
set_property PACKAGE_PIN AG2 [get_ports pcie_rx_p[2] ] 
set_property PACKAGE_PIN AH4 [get_ports pcie_rx_p[3] ] 
set_property PACKAGE_PIN AJ2 [get_ports pcie_rx_p[4] ] 
set_property PACKAGE_PIN AK4 [get_ports pcie_rx_p[5] ] 
set_property PACKAGE_PIN AL2 [get_ports pcie_rx_p[6] ] 
set_property PACKAGE_PIN AM4 [get_ports pcie_rx_p[7] ] 
set_property PACKAGE_PIN AN2 [get_ports pcie_rx_p[8] ] 
set_property PACKAGE_PIN AP4 [get_ports pcie_rx_p[9] ] 
set_property PACKAGE_PIN AD7 [get_ports pcie_tx_n[0] ] 
set_property PACKAGE_PIN AE5 [get_ports pcie_tx_n[1] ] 
set_property PACKAGE_PIN AP7 [get_ports pcie_tx_n[10]] 
set_property PACKAGE_PIN AR5 [get_ports pcie_tx_n[11]] 
set_property PACKAGE_PIN AT7 [get_ports pcie_tx_n[12]] 
set_property PACKAGE_PIN AU5 [get_ports pcie_tx_n[13]] 
set_property PACKAGE_PIN AW5 [get_ports pcie_tx_n[14]] 
set_property PACKAGE_PIN AY3 [get_ports pcie_tx_n[15]] 
set_property PACKAGE_PIN AF7 [get_ports pcie_tx_n[2] ] 
set_property PACKAGE_PIN AG5 [get_ports pcie_tx_n[3] ] 
set_property PACKAGE_PIN AH7 [get_ports pcie_tx_n[4] ] 
set_property PACKAGE_PIN AJ5 [get_ports pcie_tx_n[5] ] 
set_property PACKAGE_PIN AK7 [get_ports pcie_tx_n[6] ] 
set_property PACKAGE_PIN AL5 [get_ports pcie_tx_n[7] ] 
set_property PACKAGE_PIN AM7 [get_ports pcie_tx_n[8] ] 
set_property PACKAGE_PIN AN5 [get_ports pcie_tx_n[9] ] 
set_property PACKAGE_PIN AD8 [get_ports pcie_tx_p[0] ] 
set_property PACKAGE_PIN AE6 [get_ports pcie_tx_p[1] ] 
set_property PACKAGE_PIN AP8 [get_ports pcie_tx_p[10]] 
set_property PACKAGE_PIN AR6 [get_ports pcie_tx_p[11]] 
set_property PACKAGE_PIN AT8 [get_ports pcie_tx_p[12]]
set_property PACKAGE_PIN AU6 [get_ports pcie_tx_p[13]]
set_property PACKAGE_PIN AW6 [get_ports pcie_tx_p[14]] 
set_property PACKAGE_PIN AY4 [get_ports pcie_tx_p[15]] 
set_property PACKAGE_PIN AF8 [get_ports pcie_tx_p[2] ] 
set_property PACKAGE_PIN AG6 [get_ports pcie_tx_p[3] ] 
set_property PACKAGE_PIN AH8 [get_ports pcie_tx_p[4] ] 
set_property PACKAGE_PIN AJ6 [get_ports pcie_tx_p[5] ] 
set_property PACKAGE_PIN AK8 [get_ports pcie_tx_p[6] ] 
set_property PACKAGE_PIN AL6 [get_ports pcie_tx_p[7] ] 
set_property PACKAGE_PIN AM8 [get_ports pcie_tx_p[8] ] 
set_property PACKAGE_PIN AN6 [get_ports pcie_tx_p[9] ] 
set_property -dict {LOC AH12 } [get_ports pcie_refclk_p] ;# MGTREFCLK0P_225 (for x16 or x8 bifurcated lanes 8-16)
set_property -dict {LOC AH11 } [get_ports pcie_refclk_n] ;# MGTREFCLK0N_225 (for x16 or x8 bifurcated lanes 8-16)
set_property -dict {LOC AM25 IOSTANDARD LVCMOS12 } [get_ports pcie_rst_n]

# 100 MHz MGT reference clock
create_clock -period 10 -name pcie_mgt_refclk [get_ports pcie_refclk_p]

set_false_path -from [get_ports {pcie_rst_n}]
set_input_delay 0 [get_ports {pcie_rst_n}]
