# Compiler and flags
IVERILOG = iverilog
VVP = vvp
TARGET = sim.vvp

# Your Verilog source files
SRC = total_tb.v riscv-core.v alu.v branch_unit.v control_unit.v data_memory.v instr_decode.v instruction_memory.v programcounter.v registers.v 

# Default rule
all: run

# Compile
compile:
	$(IVERILOG) -o $(TARGET) $(SRC)

# Run the simulation
run: compile
	$(VVP) $(TARGET)

# Clean files
clean:
	rm -f $(TARGET) *.vcd

