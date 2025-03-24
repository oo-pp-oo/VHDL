################################################
#
# Makefile for a VHDL project
# using NexysA7 board
# yosys flow
#
# Albert Comerma
# v0.1 July 2024
# Pere Palà
# v1.0 March 2025
#
# RUN from an environment :
#     $ nix develop github:openxc7/toolchain-nix
#################################################

PROJECT = top
SIM_TOP = top_tb

PROJECT_SRC_FILES =  UART_RX.vhd top.vhd
SIM_SRC_FILES = UART_generator.vhd UART_RX.vhd top.vhd  top_tb.vhd
STOP_TIME ?= 400us 

# Other simulation parameters
GHDL_SIM_OPT    = --stop-time=$(STOP_TIME)
FORMAT          = ghw
EXTENSION       = $(FORMAT)
GHDL_SIM_RES    = --wave=$(SIM_TOP).$(EXTENSION)
WAVEFORM_VIEWER = gtkwave

# Family and Board-Related stuff
FAMILY     = artix7
PART       = xc7a100tcsg324-1
BOARD      = nexys_a7_100
DBPART     = $(shell echo ${PART} | sed -e 's/-[0-9]//g')
SPEEDGRADE = $(shell echo ${PART} | sed -e 's/.*\-\([0-9]\)/\1/g')
BOARD     ?= UNKNOWN
JTAG_LINK ?= --board ${BOARD}
XDC       ?= Nexys-A7-100T-Master.xdc


# ChipDB-related stuff
CHIPDB ?= chipdb
ifeq ($(CHIPDB),)
CHIPDB = chipdb/
endif

PYPY3 ?= python3

# Project Naming, etc
TOP ?= ${PROJECT}
TOP_MODULE ?= ${TOP}
TOP_VHDL ?= ${TOP}.vhd

PNR_DEBUG ?= # --verbose --debug


# MAKE RULES:
# Analyze syntax with ghdl
.PHONY: compile
compile: 
	ghdl -a --std=08 $(PROJECT_SRC_FILES)

# Elaborate TOP design with ghdl
.PHONY: elab
elab: compile
	ghdl -e --std=08 top

# Everything 
.PHONY: all
all: compile elab ${PROJECT}.bit

#Program board from command line after building
.PHONY: program
program: ${PROJECT}.bit
	openFPGALoader ${JTAG_LINK} --bitstream $<

#${PROJECT}.json: ${TOP_VHDL} ${ADDITIONAL_SOURCES}
#	ghdl -a --std=08 ${TOP_VHDL}
#	yosys -m ghdl -p "ghdl --std=08 ${TOP_MODULE}; prep; show -stretch -prefix count -format dot; synth_xilinx -flatten -abc9 ${SYNTH_OPTS} -arch xc7 -top ${TOP_MODULE}; write_json ${PROJECT}.json" | tee yosys.log

${PROJECT}.json: ${TOP_VHDL} ${ADDITIONAL_SOURCES}
	ghdl -a --std=08 ${TOP_VHDL}
	yosys -m ghdl -p "\
		ghdl --std=08 ${TOP_MODULE}; \
		prep; \
		show -stretch -prefix count -format dot; \
		synth_xilinx -flatten -abc9 ${SYNTH_OPTS} -arch xc7 -top ${TOP_MODULE}; \
		write_json ${PROJECT}.json" | tee yosys.log


# The chip database only needs to be generated once
# that is why we don't clean it with make clean
${CHIPDB}/${DBPART}.bin:
	${PYPY3} ${NEXTPNR_XILINX_PYTHON_DIR}/bbaexport.py --device ${PART} --bba ${DBPART}.bba
	bbasm -l ${DBPART}.bba ${CHIPDB}/${DBPART}.bin
	rm -f ${DBPART}.bba

${PROJECT}.fasm: ${PROJECT}.json ${CHIPDB}/${DBPART}.bin ${XDC}
	nextpnr-xilinx --chipdb ${CHIPDB}/${DBPART}.bin --xdc ${XDC} --json ${PROJECT}.json --fasm $@ ${PNR_ARGS} ${PNR_DEBUG}

${PROJECT}.frames: ${PROJECT}.fasm
	fasm2frames --part ${PART} --db-root ${PRJXRAY_DB_DIR}/${FAMILY} $< > $@

${PROJECT}.bit: ${PROJECT}.frames
	xc7frames2bit --part_file ${PRJXRAY_DB_DIR}/${FAMILY}/${PART}/part.yaml --part_name ${PART} --frm_file $< --output_file $@

######################################################################
# Simulation part
######################################################################
.PHONY: simview 
simcompile: 
	ghdl -a --std=08 -Wall $(SIM_SRC_FILES)

simelaborate: simcompile
	ghdl -e --std=08 $(SIM_TOP)

simrun: simelaborate
	@echo "Running simulation with STOP_TIME=$(STOP_TIME)"
	ghdl -r --std=08 $(SIM_TOP) $(GHDL_SIM_OPT) $(GHDL_SIM_RES)

simview: simrun
	$(WAVEFORM_VIEWER) $(SIM_TOP).$(EXTENSION) &
######################################################################

.PHONY: clean
clean:
	@rm -f *.ghw
	@rm -f *.bit
	@rm -f *.frames
	@rm -f *.fasm
	@rm -f *.json
	@rm -f *.cf
	@rm -rf *.o
	@rm -rf *.dot
	@rm -rf ${PROJECT}
	@rm -rf ${TEST}
