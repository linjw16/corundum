# XDC constraints for the Resnics F1000 board
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

# LEDs
set_property -dict {LOC J11 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 4} [get_ports led_sreg_d]
set_property -dict {LOC H10 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 4} [get_ports led_sreg_ld]
set_property -dict {LOC H11 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 4} [get_ports led_sreg_clk]
set_property -dict {LOC G11 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports {led_bmc[0]}]
set_property -dict {LOC H13 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 12} [get_ports {led_bmc[1]}]
set_property -dict {LOC G12 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 4} [get_ports {led_exp[0]}]
set_property -dict {LOC H14 IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 4} [get_ports {led_exp[1]}]

set_false_path -to [get_ports {led_sreg_d led_sreg_ld led_sreg_clk led_bmc[*] led_exp[*]}]
set_output_delay 0 [get_ports {led_sreg_d led_sreg_ld led_sreg_clk led_bmc[*] led_exp[*]}]

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
