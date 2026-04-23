#!/bin/bash
# ============================================================
# Run all ALU simulations
# Usage: bash run_all.sh
# Requires: iverilog (Icarus Verilog)
# ============================================================

SRCS="dff_posedge.v full_adder.v adder_8bit.v subtractor_8bit.v \
      restoring_divider.v booth_multiplier.v register_8bit.v \
      control_unit.v alu_8bit.v"

echo "========================================"
echo "  8-bit ALU Simulation Runner"
echo "========================================"

run_sim() {
    local name=$1
    local tb=$2
    echo ""
    echo "--- $name ---"
    iverilog -o sim_out $SRCS $tb && vvp sim_out
    rm -f sim_out
}

run_sim "Adder"       "tb_adder_8bit.v"
run_sim "Subtractor"  "tb_subtractor_8bit.v"
run_sim "Multiplier"  "tb_booth_multiplier.v"
run_sim "Divider"     "tb_restoring_divider.v"
run_sim "Full ALU"    "tb_alu_8bit.v"

echo ""
echo "========================================"
echo "  All simulations complete!"
echo "========================================"
