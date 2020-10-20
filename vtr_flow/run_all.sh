#!/bin/bash

python3 run_flow_comparison_200t.py 10 4 /mnt/comparison_results/final_common_abc_200t/ ./benchmarks/verilog/and_latch.v ./benchmarks/verilog/bgm.v ./benchmarks/verilog/blob_merge.v ./benchmarks/verilog/diffeq1.v ./benchmarks/verilog/diffeq2.v ./benchmarks/odin_comparisons/fir_filter.v ./benchmarks/verilog/multiclock_output_and_latch.v ./benchmarks/verilog/multiclock_reader_writer.v ./benchmarks/verilog/sha.v ./benchmarks/verilog/single_ff.v ./benchmarks/verilog/stereovision1.v ./benchmarks/verilog/stereovision3.v ./benchmarks/verilog/single_wire.v ./benchmarks/odin_comparisons/mkPktMerge.v ./benchmarks/verilog/stereovision0.v ./benchmarks/verilog/stereovision2.v > 200t.txt &

# nohup python3 run_flow_comparison_def_abc_200t.py 10 2 /mnt/comparison_results/final_200t/ ./benchmarks/verilog/and_latch.v ./benchmarks/verilog/bgm.v ./benchmarks/verilog/blob_merge.v ./benchmarks/verilog/diffeq1.v ./benchmarks/verilog/diffeq2.v ./benchmarks/odin_comparisons/fir_filter.v ./benchmarks/verilog/multiclock_output_and_latch.v ./benchmarks/verilog/multiclock_reader_writer.v ./benchmarks/verilog/sha.v ./benchmarks/verilog/single_ff.v ./benchmarks/verilog/stereovision1.v ./benchmarks/verilog/stereovision3.v ./benchmarks/verilog/single_wire.v ./benchmarks/odin_comparisons/mkPktMerge.v ./benchmarks/verilog/stereovision0.v ./benchmarks/verilog/stereovision2.v >> 200t.txt &

# nohup python3 run_flow_comparison_def_abc_auto.py 10 10 /mnt/comparison_results/final_auto/ ./benchmarks/odin_comparisons/arm_core.v > arm_core.txt &

python3 run_flow_comparison_auto.py 3 2 /mnt/comparison_results/final_common_abc_auto/ ./benchmarks/odin_comparisons/arm_core.v > arm_core.txt &

tail -f 200t.txt arm_core.txt
