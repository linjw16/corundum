# Corundum mqnic for F1000@ZU19EG

## Introduction

This design targets the Silicom F1000@ZU19EG FPGA board.

FPGA: zu19eg-ffvc1760-2-e
PHY: 25G BASE-R PHY IP core and internal GTY transceiver

## How to build

```
make SUBDIRS=fpga_l3fwd 
```

Run make to build.  Ensure that the Xilinx Vivado toolchain components are
in PATH.

Run make to build the driver.  Ensure the headers for the running kernel are
installed, otherwise the driver cannot be compiled.

## How to test

Run make program to program the F1000@ZU19EG board with Vivado.  Then load the
driver with insmod mqnic.ko.  Check dmesg for output from driver
initialization.


Citation

If you use Corundum in your project, please cite one of the following papers and/or link to the project on GitHub:

```
@inproceedings{forencich2020fccm,
    author = {Alex Forencich and Alex C. Snoeren and George Porter and George Papen},
    title = {Corundum: An Open-Source {100-Gbps} {NIC}},
    booktitle = {28th IEEE International Symposium on Field-Programmable Custom Computing Machines},
    year = {2020},
}
```