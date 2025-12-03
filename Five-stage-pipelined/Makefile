# Tools
IVERILOG = iverilog
VVP = vvp

# Output simulation file
TARGET = sim.vvp

# Verilog sources (order matters!)
SRC =  \
    alu.v \
    branch_unit.v \
    control_unit.v \
    instr_decode.v \
    registers.v \
    programcounter.v \
    unified_memory.v \
    forward_unit.v\
    stalling_unit.v\
    riscv-core.v \
    total_tb.v

# Default rule
all: run

# Compile into VVP simulation
compile:
	$(IVERILOG) -Wall -o $(TARGET) $(SRC)

# Run simulation
run: compile
	$(VVP) $(TARGET)

# Cleanup
clean:
	rm -f $(TARGET) *.vcd
