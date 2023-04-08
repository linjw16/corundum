# Corundum mqnic for RESNICS Stargate F1000

## Introduction

This design targets the RESNICS Stargate F1000@ZU19EG FPGA board.

* FPGA: zu19eg-ffvc1760-2-e
* MAC: Xilinx 100G CMAC
* PHY: 100G CAUI-4 CMAC and internal GTY transceivers
* RAM: 16GB DDR4 SDRAM x 72 bits

## How to build

Run make to build.  Ensure that the Xilinx Vivado toolchain components are
in PATH.

Run make to build the driver.  Ensure the headers for the running kernel are
installed, otherwise the driver cannot be compiled.

## How to test

Run make program to program the F1000@ZU19EG board with Vivado.  Then load the
driver with insmod mqnic.ko.  Check dmesg for output from driver
initialization.
