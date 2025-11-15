#!/bin/bash
set -e

if [ -z "$1" ]; then
    echo "Usage: ./build.sh <file.c or file.S>"
    exit 1
fi

SRC="$1"
ELF="program.elf"
BIN="program.bin"
HEX="/home/user/Desktop/RISC-V-CPU-DESIGN/instructions.hex"

echo "=== Building RISC-V RV32I Program ==="
echo "Source file: $SRC"

case "$SRC" in
    *.c)
        echo "[1] Compiling C source..."
        riscv64-unknown-elf-gcc -march=rv32i -mabi=ilp32 -nostdlib -Ttext=0 \
        "$SRC" -o "$ELF"
        ;;

    *.S|*.s)
        echo "[1] Assembling assembly source..."
        # *** IMPORTANT FIX: Use GCC as assembler, not 'as' ***
        riscv64-unknown-elf-gcc -march=rv32i -mabi=ilp32 -nostdlib -Ttext=0 \
        "$SRC" -o "$ELF"
        ;;
    *)
        echo "Unsupported file type"
        exit 1
        ;;
esac

echo "[2] Converting ELF → BIN"
riscv64-unknown-elf-objcopy -O binary "$ELF" "$BIN"

echo "[3] Converting BIN → HEX"
hexdump -ve '1/4 "%08x\n"' "$BIN" > "$HEX"

echo "Done. Load $HEX into your Verilog core."

