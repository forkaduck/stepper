.PHONY: all
.DELETE_ON_ERROR:
TOPMOD  := stepper
YSFIL := $(TOPMOD).ys
VCDFILE := $(TOPMOD).vcd
SIMPROG := $(TOPMOD)_tb
RPTFILE := $(TOPMOD).rpt
BINFILE := $(TOPMOD).bin
SIMFILE := $(SIMPROG).cpp
VDIRFB  := ./obj_dir
all: $(VCDFILE)

.PHONY: clean
clean:
	rm -rf $(VDIRFB)/ $(SIMPROG) $(VCDFILE) $(TOPMOD)/ $(BINFILE) $(RPTFILE)
	rm -rf $(TOPMOD).json ulx3s_out.config ulx3s.bit

##
## Find all of the Verilog dependencies and submodules
##
DEPS := $(wildcard $(VDIRFB)/*.d)

## Include any of these submodules in the Makefile
## ... but only if we are not building the "clean" target
## which would (oops) try to build those dependencies again
##
ifneq ($(MAKECMDGOALS),clean)
ifneq ($(DEPS),)
include $(DEPS)
endif
endif


ulx3s.bit: ulx3s_out.config
	ecppack ulx3s_out.config ulx3s.bit --idcode 0x21111043

ulx3s_out.config: $(TOPMOD).json
	nextpnr-ecp5 --25k --json $(TOPMOD).json  \
		--lpf ulx3s_v20.lpf \
		--textcfg ulx3s_out.config

$(TOPMOD).json: src/$(TOPMOD).v
	yosys -p "read_verilog src/*.v; synth_ecp5 -noccu2 -nomux -nodram -json $(TOPMOD).json"

prog: ulx3s.bit
	openFPGALoader -b ulx3s -v -m ulx3s.bit
