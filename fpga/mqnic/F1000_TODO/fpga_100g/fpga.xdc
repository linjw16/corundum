# XDC constraints for the RESNICS F1000
# part: zu19eg-ffvc1760-2-e

# General configuration
# set_property CFGBVS GND                                [current_design]
# set_property CONFIG_VOLTAGE 1.8                        [current_design]
set_property BITSTREAM.GENERAL.COMPRESS true           [current_design]
set_property BITSTREAM.CONFIG.EXTMASTERCCLK_EN disable [current_design]
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

# reference clock from QSFP, 25 MHz
# 25 MHz
# set_property -dict {LOC AU21 IOSTANDARD DIFF_SSTL12} [get_ports clk_25mhz_p]
# set_property -dict {LOC AV21 IOSTANDARD DIFF_SSTL12} [get_ports clk_25mhz_n]
# create_clock -period 40.000 -name clk_25mhz [get_ports clk_25mhz_p]

# E7 is not a global clock capable input, so need to set CLOCK_DEDICATED_ROUTE to satisfy DRC
# set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets init_clk_ibuf_inst/O]
set_property CLOCK_DEDICATED_ROUTE ANY_CMT_COLUMN [get_nets clk_100mhz_ibufg]

# DDR4 refclk1
set_property -dict {LOC H20 IOSTANDARD DIFF_SSTL12} [get_ports clk_ddr4_refclk1_p]
set_property -dict {LOC H19 IOSTANDARD DIFF_SSTL12} [get_ports clk_ddr4_refclk1_n]
create_clock -period 3.750 -name clk_ddr4_refclk1 [get_ports clk_ddr4_refclk1_p]

# DDR ref clock sharing
set_property -quiet CLOCK_DEDICATED_ROUTE BACKBONE [get_pins -quiet -hier -filter {name =~ */u_ddr4_infrastructure/gen_mmcme*.u_mmcme_adv_inst/CLKIN1 && name =~*ddr4_c0_inst*}]
# set_property -quiet CLOCK_DEDICATED_ROUTE BACKBONE [get_pins -quiet -hier -filter {name =~ */u_ddr4_infrastructure/gen_mmcme*.u_mmcme_adv_inst/CLKIN1 && name =~*ddr4_c1_inst*}]

# DDR4 refclk2           TODO
# set_property -dict {LOC G29  IOSTANDARD DIFF_SSTL12} [get_ports clk_ddr4_refclk2_p]
# set_property -dict {LOC G28  IOSTANDARD DIFF_SSTL12} [get_ports clk_ddr4_refclk2_n]
# create_clock -period 3.750 -name clk_ddr4_refclk2 [get_ports clk_ddr4_refclk1_p]

# DDR ref clock sharing
# set_property -quiet CLOCK_DEDICATED_ROUTE BACKBONE [get_pins -quiet -hier -filter {name =~ */u_ddr4_infrastructure/gen_mmcme*.u_mmcme_adv_inst/CLKIN1 && name =~*ddr4_c2_inst*}]
# set_property -quiet CLOCK_DEDICATED_ROUTE BACKBONE [get_pins -quiet -hier -filter {name =~ */u_ddr4_infrastructure/gen_mmcme*.u_mmcme_adv_inst/CLKIN1 && name =~*ddr4_c3_inst*}]

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
# set_property -dict {LOC H2 IOSTANDARD LVCMOS33} [get_ports misc_ucoax] ; from u.FL J5 (PPS IN)

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

# PCIe Interface
set_property PACKAGE_PIN AE1 [get_ports pcie_rx_n[0]]
set_property PACKAGE_PIN AF3 [get_ports pcie_rx_n[1]]
set_property PACKAGE_PIN AR1 [get_ports pcie_rx_n[10]]
set_property PACKAGE_PIN AT3 [get_ports pcie_rx_n[11]]
set_property PACKAGE_PIN AU1 [get_ports pcie_rx_n[12]]
set_property PACKAGE_PIN AV3 [get_ports pcie_rx_n[13]]
set_property PACKAGE_PIN AW1 [get_ports pcie_rx_n[14]]
set_property PACKAGE_PIN BA1 [get_ports pcie_rx_n[15]]
set_property PACKAGE_PIN AG1 [get_ports pcie_rx_n[2]]
set_property PACKAGE_PIN AH3 [get_ports pcie_rx_n[3]]
set_property PACKAGE_PIN AJ1 [get_ports pcie_rx_n[4]]
set_property PACKAGE_PIN AK3 [get_ports pcie_rx_n[5]]
set_property PACKAGE_PIN AL1 [get_ports pcie_rx_n[6]]
set_property PACKAGE_PIN AM3 [get_ports pcie_rx_n[7]]
set_property PACKAGE_PIN AN1 [get_ports pcie_rx_n[8]]
set_property PACKAGE_PIN AP3 [get_ports pcie_rx_n[9]]
set_property PACKAGE_PIN AE2 [get_ports pcie_rx_p[0]]
set_property PACKAGE_PIN AF4 [get_ports pcie_rx_p[1]]
set_property PACKAGE_PIN AR2 [get_ports pcie_rx_p[10]]
set_property PACKAGE_PIN AT4 [get_ports pcie_rx_p[11]]
set_property PACKAGE_PIN AU2 [get_ports pcie_rx_p[12]]
set_property PACKAGE_PIN AV4 [get_ports pcie_rx_p[13]]
set_property PACKAGE_PIN AW2 [get_ports pcie_rx_p[14]]
set_property PACKAGE_PIN BA2 [get_ports pcie_rx_p[15]]
set_property PACKAGE_PIN AG2 [get_ports pcie_rx_p[2]]
set_property PACKAGE_PIN AH4 [get_ports pcie_rx_p[3]]
set_property PACKAGE_PIN AJ2 [get_ports pcie_rx_p[4]]
set_property PACKAGE_PIN AK4 [get_ports pcie_rx_p[5]]
set_property PACKAGE_PIN AL2 [get_ports pcie_rx_p[6]]
set_property PACKAGE_PIN AM4 [get_ports pcie_rx_p[7]]
set_property PACKAGE_PIN AN2 [get_ports pcie_rx_p[8]]
set_property PACKAGE_PIN AP4 [get_ports pcie_rx_p[9]]
set_property PACKAGE_PIN AD7 [get_ports pcie_tx_n[0]]
set_property PACKAGE_PIN AE5 [get_ports pcie_tx_n[1]]
set_property PACKAGE_PIN AP7 [get_ports pcie_tx_n[10]]
set_property PACKAGE_PIN AR5 [get_ports pcie_tx_n[11]]
set_property PACKAGE_PIN AT7 [get_ports pcie_tx_n[12]]
set_property PACKAGE_PIN AU5 [get_ports pcie_tx_n[13]]
set_property PACKAGE_PIN AW5 [get_ports pcie_tx_n[14]]
set_property PACKAGE_PIN AY3 [get_ports pcie_tx_n[15]]
set_property PACKAGE_PIN AF7 [get_ports pcie_tx_n[2]]
set_property PACKAGE_PIN AG5 [get_ports pcie_tx_n[3]]
set_property PACKAGE_PIN AH7 [get_ports pcie_tx_n[4]]
set_property PACKAGE_PIN AJ5 [get_ports pcie_tx_n[5]]
set_property PACKAGE_PIN AK7 [get_ports pcie_tx_n[6]]
set_property PACKAGE_PIN AL5 [get_ports pcie_tx_n[7]]
set_property PACKAGE_PIN AM7 [get_ports pcie_tx_n[8]]
set_property PACKAGE_PIN AN5 [get_ports pcie_tx_n[9]]
set_property PACKAGE_PIN AD8 [get_ports pcie_tx_p[0]]
set_property PACKAGE_PIN AE6 [get_ports pcie_tx_p[1]]
set_property PACKAGE_PIN AP8 [get_ports pcie_tx_p[10]]
set_property PACKAGE_PIN AR6 [get_ports pcie_tx_p[11]]
set_property PACKAGE_PIN AT8 [get_ports pcie_tx_p[12]]
set_property PACKAGE_PIN AU6 [get_ports pcie_tx_p[13]]
set_property PACKAGE_PIN AW6 [get_ports pcie_tx_p[14]]
set_property PACKAGE_PIN AY4 [get_ports pcie_tx_p[15]]
set_property PACKAGE_PIN AF8 [get_ports pcie_tx_p[2]]
set_property PACKAGE_PIN AG6 [get_ports pcie_tx_p[3]]
set_property PACKAGE_PIN AH8 [get_ports pcie_tx_p[4]]
set_property PACKAGE_PIN AJ6 [get_ports pcie_tx_p[5]]
set_property PACKAGE_PIN AK8 [get_ports pcie_tx_p[6]]
set_property PACKAGE_PIN AL6 [get_ports pcie_tx_p[7]]
set_property PACKAGE_PIN AM8 [get_ports pcie_tx_p[8]]
set_property PACKAGE_PIN AN6 [get_ports pcie_tx_p[9]]
set_property -dict {LOC AH12 } [get_ports pcie_refclk_p] ;# MGTREFCLK0P_225 (for x16 or x8 bifurcated lanes 8-16)
set_property -dict {LOC AH11 } [get_ports pcie_refclk_n] ;# MGTREFCLK0N_225 (for x16 or x8 bifurcated lanes 8-16)
set_property -dict {LOC AM25 IOSTANDARD LVCMOS12 } [get_ports pcie_rst_n]

# 100 MHz MGT reference clock
create_clock -period 10 -name pcie_mgt_refclk [get_ports pcie_refclk_p]

set_false_path -from [get_ports {pcie_rst_n}]
set_input_delay 0 [get_ports {pcie_rst_n}]

# DDR4 C0
# 5x K4A8G165WB-BCTD / MT40A512M16HA-075E
set_property -dict {LOC L19 IOSTANDARD SSTL12_DCI} [get_ports ddr4_c0_adr[0]]
set_property -dict {LOC J21 IOSTANDARD SSTL12_DCI} [get_ports ddr4_c0_adr[1]]
set_property -dict {LOC K19 IOSTANDARD SSTL12_DCI} [get_ports ddr4_c0_adr[2]]
set_property -dict {LOC G20 IOSTANDARD SSTL12_DCI} [get_ports ddr4_c0_adr[3]]
set_property -dict {LOC P21 IOSTANDARD SSTL12_DCI} [get_ports ddr4_c0_adr[4]]
set_property -dict {LOC G22 IOSTANDARD SSTL12_DCI} [get_ports ddr4_c0_adr[5]]
set_property -dict {LOC M20 IOSTANDARD SSTL12_DCI} [get_ports ddr4_c0_adr[6]]
set_property -dict {LOC F20 IOSTANDARD SSTL12_DCI} [get_ports ddr4_c0_adr[7]]
set_property -dict {LOC L20 IOSTANDARD SSTL12_DCI} [get_ports ddr4_c0_adr[8]]
set_property -dict {LOC K22 IOSTANDARD SSTL12_DCI} [get_ports ddr4_c0_adr[9]]
set_property -dict {LOC K21 IOSTANDARD SSTL12_DCI} [get_ports ddr4_c0_adr[10]]
set_property -dict {LOC J19 IOSTANDARD SSTL12_DCI} [get_ports ddr4_c0_adr[11]]
set_property -dict {LOC E19 IOSTANDARD SSTL12_DCI} [get_ports ddr4_c0_adr[12]]
set_property -dict {LOC D22 IOSTANDARD SSTL12_DCI} [get_ports ddr4_c0_adr[13]]
set_property -dict {LOC M22 IOSTANDARD SSTL12_DCI} [get_ports ddr4_c0_adr[14]]
set_property -dict {LOC G21 IOSTANDARD SSTL12_DCI} [get_ports ddr4_c0_adr[15]]
set_property -dict {LOC F19 IOSTANDARD SSTL12_DCI} [get_ports ddr4_c0_adr[16]]
set_property -dict {LOC L18 IOSTANDARD SSTL12_DCI} [get_ports {ddr4_c0_ba[0]}]
set_property -dict {LOC J22 IOSTANDARD SSTL12_DCI} [get_ports {ddr4_c0_ba[1]}]
set_property -dict {LOC P18 IOSTANDARD SSTL12_DCI} [get_ports {ddr4_c0_bg[0]}]
set_property -dict {LOC H21 IOSTANDARD SSTL12_DCI} [get_ports {ddr4_c0_bg[1]}]
set_property -dict {LOC N20 IOSTANDARD DIFF_SSTL12_DCI} [get_ports {ddr4_c0_ck_t}]
set_property -dict {LOC N19 IOSTANDARD DIFF_SSTL12_DCI} [get_ports {ddr4_c0_ck_c}]
set_property -dict {LOC N18 IOSTANDARD SSTL12_DCI} [get_ports {ddr4_c0_cke}]
set_property -dict {LOC E20 IOSTANDARD SSTL12_DCI} [get_ports {ddr4_c0_cs_n}]
set_property -dict {LOC M21 IOSTANDARD SSTL12_DCI} [get_ports {ddr4_c0_act_n}]
set_property -dict {LOC N21 IOSTANDARD SSTL12_DCI} [get_ports {ddr4_c0_odt}]
set_property -dict {LOC K20 IOSTANDARD SSTL12_DCI} [get_ports {ddr4_c0_par}]
set_property -dict {LOC M18 IOSTANDARD LVCMOS12} [get_ports {ddr4_c0_reset_n}]
set_property -dict {LOC E22 IOSTANDARD LVCMOS12} [get_ports {ddr4_c0_alert_n}]
# set_property -dict {LOC AU20 IOSTANDARD LVCMOS12} [get_ports {ddr4_c0_ten}]
# TODO
set_property -dict {LOC B20 IOSTANDARD POD12_DCI} [get_ports {ddr4_c0_dq[0]}]
set_property -dict {LOC B22 IOSTANDARD POD12_DCI} [get_ports {ddr4_c0_dq[1]}]
set_property -dict {LOC C20 IOSTANDARD POD12_DCI} [get_ports {ddr4_c0_dq[2]}]
set_property -dict {LOC A22 IOSTANDARD POD12_DCI} [get_ports {ddr4_c0_dq[3]}]
set_property -dict {LOC A20 IOSTANDARD POD12_DCI} [get_ports {ddr4_c0_dq[4]}]
set_property -dict {LOC B23 IOSTANDARD POD12_DCI} [get_ports {ddr4_c0_dq[5]}]
set_property -dict {LOC A19 IOSTANDARD POD12_DCI} [get_ports {ddr4_c0_dq[6]}]
set_property -dict {LOC A23 IOSTANDARD POD12_DCI} [get_ports {ddr4_c0_dq[7]}]
set_property -dict {LOC F24 IOSTANDARD POD12_DCI} [get_ports {ddr4_c0_dq[8]}]
set_property -dict {LOC F27 IOSTANDARD POD12_DCI} [get_ports {ddr4_c0_dq[9]}]
set_property -dict {LOC E24 IOSTANDARD POD12_DCI} [get_ports {ddr4_c0_dq[10]}]
set_property -dict {LOC D28 IOSTANDARD POD12_DCI} [get_ports {ddr4_c0_dq[11]}]
set_property -dict {LOC F25 IOSTANDARD POD12_DCI} [get_ports {ddr4_c0_dq[12]}]
set_property -dict {LOC F28 IOSTANDARD POD12_DCI} [get_ports {ddr4_c0_dq[13]}]
set_property -dict {LOC E25 IOSTANDARD POD12_DCI} [get_ports {ddr4_c0_dq[14]}]
set_property -dict {LOC D27 IOSTANDARD POD12_DCI} [get_ports {ddr4_c0_dq[15]}]
set_property -dict {LOC N23 IOSTANDARD POD12_DCI} [get_ports {ddr4_c0_dq[16]}]
set_property -dict {LOC N25 IOSTANDARD POD12_DCI} [get_ports {ddr4_c0_dq[17]}]
set_property -dict {LOC P23 IOSTANDARD POD12_DCI} [get_ports {ddr4_c0_dq[18]}]
set_property -dict {LOC N24 IOSTANDARD POD12_DCI} [get_ports {ddr4_c0_dq[19]}]
set_property -dict {LOC L23 IOSTANDARD POD12_DCI} [get_ports {ddr4_c0_dq[20]}]
set_property -dict {LOC M25 IOSTANDARD POD12_DCI} [get_ports {ddr4_c0_dq[21]}]
set_property -dict {LOC M23 IOSTANDARD POD12_DCI} [get_ports {ddr4_c0_dq[22]}]
set_property -dict {LOC L25 IOSTANDARD POD12_DCI} [get_ports {ddr4_c0_dq[23]}]
set_property -dict {LOC A24 IOSTANDARD POD12_DCI} [get_ports {ddr4_c0_dq[24]}]
set_property -dict {LOC C25 IOSTANDARD POD12_DCI} [get_ports {ddr4_c0_dq[25]}]
set_property -dict {LOC B27 IOSTANDARD POD12_DCI} [get_ports {ddr4_c0_dq[26]}]
set_property -dict {LOC C24 IOSTANDARD POD12_DCI} [get_ports {ddr4_c0_dq[27]}]
set_property -dict {LOC A25 IOSTANDARD POD12_DCI} [get_ports {ddr4_c0_dq[28]}]
set_property -dict {LOC C26 IOSTANDARD POD12_DCI} [get_ports {ddr4_c0_dq[29]}]
set_property -dict {LOC A27 IOSTANDARD POD12_DCI} [get_ports {ddr4_c0_dq[30]}]
set_property -dict {LOC A28 IOSTANDARD POD12_DCI} [get_ports {ddr4_c0_dq[31]}]
set_property -dict {LOC C42 IOSTANDARD POD12_DCI} [get_ports {ddr4_c0_dq[32]}]
set_property -dict {LOC B36 IOSTANDARD POD12_DCI} [get_ports {ddr4_c0_dq[33]}]
set_property -dict {LOC B40 IOSTANDARD POD12_DCI} [get_ports {ddr4_c0_dq[34]}]
set_property -dict {LOC A37 IOSTANDARD POD12_DCI} [get_ports {ddr4_c0_dq[35]}]
set_property -dict {LOC B42 IOSTANDARD POD12_DCI} [get_ports {ddr4_c0_dq[36]}]
set_property -dict {LOC B37 IOSTANDARD POD12_DCI} [get_ports {ddr4_c0_dq[37]}]
set_property -dict {LOC B41 IOSTANDARD POD12_DCI} [get_ports {ddr4_c0_dq[38]}]
set_property -dict {LOC A38 IOSTANDARD POD12_DCI} [get_ports {ddr4_c0_dq[39]}]
set_property -dict {LOC B35 IOSTANDARD POD12_DCI} [get_ports {ddr4_c0_dq[40]}]
set_property -dict {LOC D33 IOSTANDARD POD12_DCI} [get_ports {ddr4_c0_dq[41]}]
set_property -dict {LOC A34 IOSTANDARD POD12_DCI} [get_ports {ddr4_c0_dq[42]}]
set_property -dict {LOC B33 IOSTANDARD POD12_DCI} [get_ports {ddr4_c0_dq[43]}]
set_property -dict {LOC A35 IOSTANDARD POD12_DCI} [get_ports {ddr4_c0_dq[44]}]
set_property -dict {LOC C33 IOSTANDARD POD12_DCI} [get_ports {ddr4_c0_dq[45]}]
set_property -dict {LOC A33 IOSTANDARD POD12_DCI} [get_ports {ddr4_c0_dq[46]}]
set_property -dict {LOC B32 IOSTANDARD POD12_DCI} [get_ports {ddr4_c0_dq[47]}]
set_property -dict {LOC B30 IOSTANDARD POD12_DCI} [get_ports {ddr4_c0_dq[48]}]
set_property -dict {LOC E31 IOSTANDARD POD12_DCI} [get_ports {ddr4_c0_dq[49]}]
set_property -dict {LOC C29 IOSTANDARD POD12_DCI} [get_ports {ddr4_c0_dq[50]}]
set_property -dict {LOC C31 IOSTANDARD POD12_DCI} [get_ports {ddr4_c0_dq[51]}]
set_property -dict {LOC A29 IOSTANDARD POD12_DCI} [get_ports {ddr4_c0_dq[52]}]
set_property -dict {LOC D31 IOSTANDARD POD12_DCI} [get_ports {ddr4_c0_dq[53]}]
set_property -dict {LOC A30 IOSTANDARD POD12_DCI} [get_ports {ddr4_c0_dq[54]}]
set_property -dict {LOC C30 IOSTANDARD POD12_DCI} [get_ports {ddr4_c0_dq[55]}]
set_property -dict {LOC F32 IOSTANDARD POD12_DCI} [get_ports {ddr4_c0_dq[56]}]
set_property -dict {LOC H30 IOSTANDARD POD12_DCI} [get_ports {ddr4_c0_dq[57]}]
set_property -dict {LOC F29 IOSTANDARD POD12_DCI} [get_ports {ddr4_c0_dq[58]}]
set_property -dict {LOC H28 IOSTANDARD POD12_DCI} [get_ports {ddr4_c0_dq[59]}]
set_property -dict {LOC F31 IOSTANDARD POD12_DCI} [get_ports {ddr4_c0_dq[60]}]
set_property -dict {LOC J30 IOSTANDARD POD12_DCI} [get_ports {ddr4_c0_dq[61]}]
set_property -dict {LOC G28 IOSTANDARD POD12_DCI} [get_ports {ddr4_c0_dq[62]}]
set_property -dict {LOC J28 IOSTANDARD POD12_DCI} [get_ports {ddr4_c0_dq[63]}]
# TODO
# set_property -dict {LOC AM14 IOSTANDARD POD12_DCI} [get_ports {ddr4_c0_dq[64]}]
# set_property -dict {LOC AR12 IOSTANDARD POD12_DCI} [get_ports {ddr4_c0_dq[65]}]
# set_property -dict {LOC AP15 IOSTANDARD POD12_DCI} [get_ports {ddr4_c0_dq[66]}]
# set_property -dict {LOC AR13 IOSTANDARD POD12_DCI} [get_ports {ddr4_c0_dq[67]}]
# set_property -dict {LOC AM15 IOSTANDARD POD12_DCI} [get_ports {ddr4_c0_dq[68]}]
# set_property -dict {LOC AT12 IOSTANDARD POD12_DCI} [get_ports {ddr4_c0_dq[69]}]
# set_property -dict {LOC AP14 IOSTANDARD POD12_DCI} [get_ports {ddr4_c0_dq[70]}]
# set_property -dict {LOC AP13 IOSTANDARD POD12_DCI} [get_ports {ddr4_c0_dq[71]}]
set_property -dict {LOC C21 IOSTANDARD DIFF_POD12_DCI} [get_ports {ddr4_c0_dqs_t[0]}]
set_property -dict {LOC B21 IOSTANDARD DIFF_POD12_DCI} [get_ports {ddr4_c0_dqs_c[0]}]
set_property -dict {LOC E26 IOSTANDARD DIFF_POD12_DCI} [get_ports {ddr4_c0_dqs_t[1]}]
set_property -dict {LOC E27 IOSTANDARD DIFF_POD12_DCI} [get_ports {ddr4_c0_dqs_c[1]}]
set_property -dict {LOC L24 IOSTANDARD DIFF_POD12_DCI} [get_ports {ddr4_c0_dqs_t[2]}]
set_property -dict {LOC K24 IOSTANDARD DIFF_POD12_DCI} [get_ports {ddr4_c0_dqs_c[2]}]
set_property -dict {LOC B25 IOSTANDARD DIFF_POD12_DCI} [get_ports {ddr4_c0_dqs_t[3]}]
set_property -dict {LOC B26 IOSTANDARD DIFF_POD12_DCI} [get_ports {ddr4_c0_dqs_c[3]}]
set_property -dict {LOC A39 IOSTANDARD DIFF_POD12_DCI} [get_ports {ddr4_c0_dqs_t[4]}]
set_property -dict {LOC A40 IOSTANDARD DIFF_POD12_DCI} [get_ports {ddr4_c0_dqs_c[4]}]
set_property -dict {LOC D34 IOSTANDARD DIFF_POD12_DCI} [get_ports {ddr4_c0_dqs_t[5]}]
set_property -dict {LOC C34 IOSTANDARD DIFF_POD12_DCI} [get_ports {ddr4_c0_dqs_c[5]}]
set_property -dict {LOC B31 IOSTANDARD DIFF_POD12_DCI} [get_ports {ddr4_c0_dqs_t[6]}]
set_property -dict {LOC A32 IOSTANDARD DIFF_POD12_DCI} [get_ports {ddr4_c0_dqs_c[6]}]
set_property -dict {LOC G30 IOSTANDARD DIFF_POD12_DCI} [get_ports {ddr4_c0_dqs_t[7]}]
set_property -dict {LOC F30 IOSTANDARD DIFF_POD12_DCI} [get_ports {ddr4_c0_dqs_c[7]}]
set_property -dict {LOC H23 IOSTANDARD DIFF_POD12_DCI} [get_ports {ddr4_c0_dqs_t[8]}]
set_property -dict {LOC G23 IOSTANDARD DIFF_POD12_DCI} [get_ports {ddr4_c0_dqs_c[8]}]
set_property -dict {LOC D19 IOSTANDARD POD12_DCI} [get_ports {ddr4_c0_dm_dbi_n[0]}]
set_property -dict {LOC G26 IOSTANDARD POD12_DCI} [get_ports {ddr4_c0_dm_dbi_n[1]}]
set_property -dict {LOC P26 IOSTANDARD POD12_DCI} [get_ports {ddr4_c0_dm_dbi_n[2]}]
set_property -dict {LOC C28 IOSTANDARD POD12_DCI} [get_ports {ddr4_c0_dm_dbi_n[3]}]
set_property -dict {LOC C36 IOSTANDARD POD12_DCI} [get_ports {ddr4_c0_dm_dbi_n[4]}]
set_property -dict {LOC E32 IOSTANDARD POD12_DCI} [get_ports {ddr4_c0_dm_dbi_n[5]}]
set_property -dict {LOC E29 IOSTANDARD POD12_DCI} [get_ports {ddr4_c0_dm_dbi_n[6]}]
set_property -dict {LOC K29 IOSTANDARD POD12_DCI} [get_ports {ddr4_c0_dm_dbi_n[7]}]
set_property -dict {LOC K27 IOSTANDARD POD12_DCI} [get_ports {ddr4_c0_dm_dbi_n[8]}]
