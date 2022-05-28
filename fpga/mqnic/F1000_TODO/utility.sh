# 1. Standalone project
corundum=/home/linjw16/E/Program_Files/prj/corundum/
pwd=/home/linjw16/E/Program_Files/prj/f1000_25g
mkdir $pwd
cp $corundum/fpga/mqnic/F1000_TODO/fpga_25g/* $pwd -RL

# 2. 10g/25g only
cd $pwd
rm ./tb/fpga_core/mqnic.py
cp $corundum/fpga/common/tb/mqnic.py ./tb/fpga_core/ -f
tcl_path=common/syn/vivado/
mkdir common/syn
mkdir $tcl_path
cp $corundum/fpga/common/syn/vivado/* ./$tcl_path
# modify ./fpga/Makefile line 117
# - XDC_FILES += ../../../common/syn/vivado/*.tcl
# + XDC_FILES += common/syn/vivado/*.tcl
# update: mqnic_app_block.v

# 3. rm all the dump lib and tb/, example/ inside
rm app/template/lib -rf
ln ../../lib/ ./app/template/lib -s
rm app/l3fwd/lib -rf
ln ../../lib/ ./app/l3fwd/lib -s
rm ./lib/*/tb/ -rf
rm ./lib/*/example/ -rf
rm ./lib/eth/lib/axis/ -rf
ln ./lib/axis/ ./lib/eth/lib/axis -s	# TODO
# rm dumy in app/*/rtl
rm app/*/rtl/common -rf
ln ../../../rtl/common/ ./app/template/rtl/common -s
ln ../../../rtl/common/ ./app/l3fwd/rtl/common -s
rm app/*/tb/*/mqnic.py
ln ../../../../tb/fpga_core/mqnic.py app/template/tb/mqnic_core_pcie_us/mqnic.py

# 4. extra lib
ln ../../avst ./lib/avst -s
ln ../../bus_wrapper ./lib/bus_wrapper -s
ln ../../fractcam ./lib/fractcam -s

# a.1 while you copy with mouse
rm ./app ./lib ./rtl/common -rf
cp $corundum/fpga/lib ./lib -r
cp $corundum/fpga/app ./app -r
mkdir ./rtl/common/
cp $corundum/fpga/common/rtl/* ./rtl/common/
cd ./app/template/rtl && rm ./common
ln ../../../rtl/common ./common -s && cd -
cd ./app/template/tb/mqnic_core_pcie_us/ && rm ./mqnic.py
ln ../../../../tb/fpga_core/mqnic.py ./mqnic.py && cd -
