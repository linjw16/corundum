# XDC constraints for the ResNIC F1000 board
# part: zu19eg-ffvc1760-2-e

# General configuration
# set_property CFGBVS GND                                [current_design]
# set_property CONFIG_VOLTAGE 1.8                        [current_design]
set_property BITSTREAM.GENERAL.COMPRESS true           [current_design]
# set_property BITSTREAM.CONFIG.EXTMASTERCCLK_EN disable [current_design]
# set_property BITSTREAM.CONFIG.SPI_32BIT_ADDR YES       [current_design]
# set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4           [current_design]
# set_property BITSTREAM.CONFIG.SPI_FALL_EDGE YES        [current_design]
# set_property BITSTREAM.CONFIG.CONFIGRATE 85.0          [current_design]
# set_property CONFIG_MODE SPIx4                         [current_design]
# set_property BITSTREAM.CONFIG.OVERTEMPSHUTDOWN Enable  [current_design]

# System clocks
# 100 MHz
set_property -dict {LOC G17 IOSTANDARD DIFF_SSTL12} [get_ports clk_100mhz_p]
set_property -dict {LOC F17 IOSTANDARD DIFF_SSTL12} [get_ports clk_100mhz_n]
create_clock -period 10.000 -name clk_100mhz [get_ports clk_100mhz_p]

# E7 is not a global clock capable input, so need to set CLOCK_DEDICATED_ROUTE to satisfy DRC
# set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets init_clk_ibuf_inst/O]
set_property CLOCK_DEDICATED_ROUTE ANY_CMT_COLUMN [get_nets clk_100mhz_ibufg]

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

# Board status
# set_property -dict {LOC A6   IOSTANDARD LVCMOS18} [get_ports {pg[0]}]
# set_property -dict {LOC C7   IOSTANDARD LVCMOS18} [get_ports {pg[1]}]

# set_false_path -from [get_ports {pg[*]}]
# set_input_delay 0 [get_ports {pg[*]}]

# QSFP28 Interfaces
set_property -dict {LOC L41 } [get_ports qsfp_0_rx_0_p] ;# MGTYRXP3_130 GTYE4_CHANNEL_X0Y15 / GTYE4_COMMON_X0Y1
set_property -dict {LOC L42 } [get_ports qsfp_0_rx_0_n] ;# MGTYRXN3_130 GTYE4_CHANNEL_X0Y15 / GTYE4_COMMON_X0Y1
set_property -dict {LOC M34 } [get_ports qsfp_0_tx_0_p] ;# MGTYTXP3_130 GTYE4_CHANNEL_X0Y15 / GTYE4_COMMON_X0Y1
set_property -dict {LOC M35 } [get_ports qsfp_0_tx_0_n] ;# MGTYTXN3_130 GTYE4_CHANNEL_X0Y15 / GTYE4_COMMON_X0Y1
set_property -dict {LOC K39 } [get_ports qsfp_0_rx_1_p] ;# MGTYRXP2_130 GTYE4_CHANNEL_X0Y14 / GTYE4_COMMON_X0Y1
set_property -dict {LOC K40 } [get_ports qsfp_0_rx_1_n] ;# MGTYRXN2_130 GTYE4_CHANNEL_X0Y14 / GTYE4_COMMON_X0Y1
set_property -dict {LOC L36 } [get_ports qsfp_0_tx_1_p] ;# MGTYTXP2_130 GTYE4_CHANNEL_X0Y14 / GTYE4_COMMON_X0Y1
set_property -dict {LOC L37 } [get_ports qsfp_0_tx_1_n] ;# MGTYTXN2_130 GTYE4_CHANNEL_X0Y14 / GTYE4_COMMON_X0Y1
set_property -dict {LOC J41 } [get_ports qsfp_0_rx_2_p] ;# MGTYRXP1_130 GTYE4_CHANNEL_X0Y13 / GTYE4_COMMON_X0Y1
set_property -dict {LOC J42 } [get_ports qsfp_0_rx_2_n] ;# MGTYRXN1_130 GTYE4_CHANNEL_X0Y13 / GTYE4_COMMON_X0Y1
set_property -dict {LOC K34 } [get_ports qsfp_0_tx_2_p] ;# MGTYTXP1_130 GTYE4_CHANNEL_X0Y13 / GTYE4_COMMON_X0Y1
set_property -dict {LOC K35 } [get_ports qsfp_0_tx_2_n] ;# MGTYTXN1_130 GTYE4_CHANNEL_X0Y13 / GTYE4_COMMON_X0Y1
set_property -dict {LOC H39 } [get_ports qsfp_0_rx_3_p] ;# MGTYRXP0_130 GTYE4_CHANNEL_X0Y12 / GTYE4_COMMON_X0Y1
set_property -dict {LOC H40 } [get_ports qsfp_0_rx_3_n] ;# MGTYRXN0_130 GTYE4_CHANNEL_X0Y12 / GTYE4_COMMON_X0Y1
set_property -dict {LOC J36 } [get_ports qsfp_0_tx_3_p] ;# MGTYTXP0_130 GTYE4_CHANNEL_X0Y12 / GTYE4_COMMON_X0Y1
set_property -dict {LOC J37 } [get_ports qsfp_0_tx_3_n] ;# MGTYTXN0_130 GTYE4_CHANNEL_X0Y12 / GTYE4_COMMON_X0Y1
set_property -dict {LOC R32 } [get_ports qsfp_0_mgt_refclk_p] ;# MGTREFCLK0P_130 from SI5394 OUT0
set_property -dict {LOC R33 } [get_ports qsfp_0_mgt_refclk_n] ;# MGTREFCLK0N_130 from SI5394 OUT0
set_property -dict {LOC G6 IOSTANDARD LVCMOS18 PULLUP true} [get_ports qsfp_0_mod_prsnt_n]
set_property -dict {LOC H8 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 4} [get_ports qsfp_0_reset_n]
set_property -dict {LOC J9 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 4} [get_ports qsfp_0_lp_mode]
set_property -dict {LOC F6 IOSTANDARD LVCMOS18 PULLUP true} [get_ports qsfp_0_intr_n]
# set_property -dict {LOC B12 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 4} [get_ports qsfp_0_i2c_scl]
# set_property -dict {LOC B11 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 4} [get_ports qsfp_0_i2c_sda]

# 322.265625 MHz MGT reference clock
create_clock -period 3.103 -name qsfp_0_mgt_refclk [get_ports qsfp_0_mgt_refclk_p]

set_false_path -to [get_ports {qsfp_0_reset_n qsfp_0_lp_mode}]
set_output_delay 0 [get_ports {qsfp_0_reset_n qsfp_0_lp_mode}]
set_false_path -from [get_ports {qsfp_0_mod_prsnt_n qsfp_0_intr_n}]
set_input_delay 0 [get_ports {qsfp_0_mod_prsnt_n qsfp_0_intr_n}]

# set_false_path -to [get_ports {qsfp_0_i2c_scl qsfp_0_i2c_sda}]
# set_output_delay 0 [get_ports {qsfp_0_i2c_scl qsfp_0_i2c_sda}]
# set_false_path -from [get_ports {qsfp_0_i2c_scl qsfp_0_i2c_sda}]
# set_input_delay 0 [get_ports {qsfp_0_i2c_scl qsfp_0_i2c_sda}]

set_property -dict {LOC G41 } [get_ports qsfp_1_rx_0_p] ;# MGTYRXP0_131 GTYE4_CHANNEL_X0Y19 / GTYE4_COMMON_X0Y2
set_property -dict {LOC G42 } [get_ports qsfp_1_rx_0_n] ;# MGTYRXP0_131 GTYE4_CHANNEL_X0Y19 / GTYE4_COMMON_X0Y2
set_property -dict {LOC H34 } [get_ports qsfp_1_tx_0_p] ;# MGTYRXP0_131 GTYE4_CHANNEL_X0Y19 / GTYE4_COMMON_X0Y2
set_property -dict {LOC H35 } [get_ports qsfp_1_tx_0_n] ;# MGTYRXP0_131 GTYE4_CHANNEL_X0Y19 / GTYE4_COMMON_X0Y2
set_property -dict {LOC F39 } [get_ports qsfp_1_rx_1_p] ;# MGTYRXP0_131 GTYE4_CHANNEL_X0Y18 / GTYE4_COMMON_X0Y2
set_property -dict {LOC F40 } [get_ports qsfp_1_rx_1_n] ;# MGTYRXP0_131 GTYE4_CHANNEL_X0Y18 / GTYE4_COMMON_X0Y2
set_property -dict {LOC G36 } [get_ports qsfp_1_tx_1_p] ;# MGTYRXP0_131 GTYE4_CHANNEL_X0Y18 / GTYE4_COMMON_X0Y2
set_property -dict {LOC G37 } [get_ports qsfp_1_tx_1_n] ;# MGTYRXP0_131 GTYE4_CHANNEL_X0Y18 / GTYE4_COMMON_X0Y2
set_property -dict {LOC E41 } [get_ports qsfp_1_rx_2_p] ;# MGTYRXP1_131 GTYE4_CHANNEL_X0Y17 / GTYE4_COMMON_X0Y2
set_property -dict {LOC E42 } [get_ports qsfp_1_rx_2_n] ;# MGTYRXN1_131 GTYE4_CHANNEL_X0Y17 / GTYE4_COMMON_X0Y2
set_property -dict {LOC F34 } [get_ports qsfp_1_tx_2_p] ;# MGTYTXP1_131 GTYE4_CHANNEL_X0Y17 / GTYE4_COMMON_X0Y2
set_property -dict {LOC F35 } [get_ports qsfp_1_tx_2_n] ;# MGTYRXP0_131 GTYE4_CHANNEL_X0Y17 / GTYE4_COMMON_X0Y2
set_property -dict {LOC D39 } [get_ports qsfp_1_rx_3_p] ;# MGTYRXP0_131 GTYE4_CHANNEL_X0Y16 / GTYE4_COMMON_X0Y2
set_property -dict {LOC D40 } [get_ports qsfp_1_rx_3_n] ;# MGTYRXP0_131 GTYE4_CHANNEL_X0Y16 / GTYE4_COMMON_X0Y2
set_property -dict {LOC E36 } [get_ports qsfp_1_tx_3_p] ;# MGTYRXP0_131 GTYE4_CHANNEL_X0Y16 / GTYE4_COMMON_X0Y2
set_property -dict {LOC E37 } [get_ports qsfp_1_tx_3_n] ;# MGTYTXN0_131 GTYE4_CHANNEL_X0Y16 / GTYE4_COMMON_X0Y2
set_property -dict {LOC L32 } [get_ports qsfp_1_mgt_refclk_p] ;# MGTREFCLK1P_230 from U12.18
set_property -dict {LOC L33 } [get_ports qsfp_1_mgt_refclk_n] ;# MGTREFCLK1N_230 from U12.17
set_property -dict {LOC F9 IOSTANDARD LVCMOS18 PULLUP true} [get_ports qsfp_1_mod_prsnt_n]
set_property -dict {LOC F7 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 4} [get_ports qsfp_1_reset_n]
set_property -dict {LOC G8 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 4} [get_ports qsfp_1_lp_mode]
set_property -dict {LOC E9 IOSTANDARD LVCMOS18 PULLUP true} [get_ports qsfp_1_intr_n]
# set_property -dict {LOC G11 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 4} [get_ports qsfp_1_i2c_scl]
# set_property -dict {LOC H11 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 4} [get_ports qsfp_1_i2c_sda]

# 322.265625 MHz MGT reference clock
create_clock -period 3.103 -name qsfp_1_mgt_refclk [get_ports qsfp_1_mgt_refclk_p]

set_false_path -to [get_ports {qsfp_1_reset_n qsfp_1_lp_mode}]
set_output_delay 0 [get_ports {qsfp_1_reset_n qsfp_1_lp_mode}]
set_false_path -from [get_ports {qsfp_1_mod_prsnt_n qsfp_1_intr_n}]
set_input_delay 0 [get_ports {qsfp_1_mod_prsnt_n qsfp_1_intr_n}]

# set_false_path -to [get_ports {qsfp_1_i2c_scl qsfp_1_i2c_sda}]
# set_output_delay 0 [get_ports {qsfp_1_i2c_scl qsfp_1_i2c_sda}]
# set_false_path -from [get_ports {qsfp_1_i2c_scl qsfp_1_i2c_sda}]
# set_input_delay 0 [get_ports {qsfp_1_i2c_scl qsfp_1_i2c_sda}]
