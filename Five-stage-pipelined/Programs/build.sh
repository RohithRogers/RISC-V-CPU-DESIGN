#!/bin/bash
set -e

if [ -z "$1" ]; then
    echo "Usage: ./build.sh <file.S or file.c>"
    exit 1
fi

SRC="$1"
ELF="program.elf"
BIN="program.bin"
HEX="/home/user/Desktop/RISC-V-CPU-DESIGN/Five-stage-pipelined/program.hex"
LINKER="link.ld"

echo "=== Building RISC-V RV32I Program ==="
echo "Source: $SRC"
echo "Using linker: $LINKER"

# --------------------------
# Compile
# --------------------------
case "$SRC" in
    *.c)
        riscv64-unknown-elf-gcc -march=rv32i -mabi=ilp32 \
            -nostdlib -T $LINKER "$SRC" -o "$ELF"
        ;;
    *.S|*.s)
        riscv64-unknown-elf-gcc -march=rv32i -mabi=ilp32 \
            -nostdlib -T $LINKER "$SRC" -o "$ELF"
        ;;
    *)
        echo "Unsupported file type!"
        exit 1
        ;;
esac

echo "[1] ELF → BIN"
riscv64-unknown-elf-objcopy -O binary "$ELF" "$BIN"

echo "[2] BIN → HEX (byte-wise clean output)"
{
    echo "@00000000"
    hexdump -v -e '1/1 "%02x\n"' "$BIN"
} > "$HEX"

echo "=== DONE ==="
echo "Generated file: $HEX"
