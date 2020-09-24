import multiprocessing
import os
import subprocess
import sys

if len(sys.argv) <= 4:
    print("Usage:", sys.argv[0], "<iterations> <num threads> <output directory> <verilog files>")
    exit(1)

output_prefix = sys.argv[3]
if not os.path.exists(output_prefix):
    print("Non existent output directory provided")
    exit(1)


def run_synthesis(verilog_file, queue):
    verilog_file_name = verilog_file.split("/")[-1]
    try:
        arch = "/mnt/comparison_results/symbiflow-arch-defs/build/xc/xc7/archs/artix7_100t/devices/xc7a100t-virt/arch.timing.xml"
        odin_command = "./scripts/run_vtr_flow.pl {} {} -delete_intermediate_files -ending_stage prevpr -abc_exe /mnt/comparison_results/symbiflow-arch-defs/env/conda/envs/symbiflow_arch_def_base/bin/yosys-abc -latch_map_script ./scripts/latch_map.py".format(
            verilog_file, arch)
        yosys_command = odin_command + " -yosys /mnt/comparison_results/symbiflow-arch-defs/env/conda/envs/symbiflow_arch_def_base/bin/yosys -yosys_script ./yosys_script.ys"

        output_prefix = sys.argv[3]
        odin_temp = output_prefix + "/temp_" + verilog_file_name + "_odin"
        yosys_temp = output_prefix + "/temp_" + verilog_file_name + "_yosys"

        odin_command += " -temp_dir " + odin_temp
        yosys_command += " -temp_dir " + yosys_temp

        error = 0
        msgs = []
        out = subprocess.run(odin_command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        if out.returncode != 0:
            msgs.append("Error running Odin II:\n" + out.stdout.decode("utf-8"))
            error |= 1

        out = subprocess.run(yosys_command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        if out.returncode != 0:
            msgs.append("Error running Yosys:\n" + out.stdout.decode("utf-8"))
            error |= 2

        queue.put(verilog_file_name)
        return (verilog_file_name, -1, error, msgs)
    except Exception as e:
        return (verilog_file_name, -1, 4, ["Exception thrown: " + str(e)])


def run_vpr(temp_dir, i):
    dir_name = temp_dir.split("/")[-1]
    split_dir_name = dir_name.split("_")
    verilog_file_name = "_".join(split_dir_name[1:-2])
    try:
        vpr_args = "--device xc7a100t-test --read_rr_graph /mnt/comparison_results/symbiflow-arch-defs/build/xc/xc7/archs/artix7_100t/devices/rr_graph_xc7a100t_test.rr_graph.real.bin \
                    --max_router_iterations 500 --routing_failure_predictor off --router_high_fanout_threshold -1 --constant_net_method route --route_chan_width 500 \
                     --router_heap bucket --clock_modeling route --place_delta_delay_matrix_calculation_method dijkstra --place_delay_model delta_override --router_lookahead connection_box_map \
                     --check_route quick --strict_checks off --allow_dangling_combinational_nodes on --disable_errors check_unbuffered_edges:check_route --congested_routing_iteration_threshold 0.8 \
                     --incremental_reroute_delay_ripup off --base_cost_type delay_normalized_length_bounded --bb_factor 10 --initial_pres_fac 4.0 --check_rr_graph off \
                     --suppress_warnings sum_pin_class:check_unbuffered_edges:load_rr_indexed_data_T_values:check_rr_node:trans_per_R:check_route:set_rr_graph_tool_comment:calculate_average_switch \
                     --read_router_lookahead /mnt/comparison_results/symbiflow-arch-defs/build/xc/xc7/archs/artix7_100t/devices/rr_graph_xc7a100t_test.lookahead.bin \
                     --read_placement_delay_lookup /mnt/comparison_results/symbiflow-arch-defs/build/xc/xc7/archs/artix7_100t/devices/rr_graph_xc7a100t_test.place_delay.bin"
        arch = "/mnt/comparison_results/symbiflow-arch-defs/build/xc/xc7/archs/artix7_100t/devices/xc7a100t-virt/arch.timing.xml"
        vpr_exe = "/mnt/comparison_results/symbiflow-arch-defs/env/conda/envs/symbiflow_arch_def_base/bin/vpr"

        blif_name = "{}/{}.pre-vpr.blif".format(temp_dir, verilog_file_name.rsplit(".", maxsplit=1)[0])
        command = "./scripts/run_vtr_flow.pl {} {} -starting_stage vpr -delete_intermediate_files -temp_dir {} -vpr_exe {}  {} --seed {}".format(
            blif_name, arch, temp_dir, vpr_exe, vpr_args, i)

        error = 0
        msgs = []
        out = subprocess.run(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        if out.returncode != 0:
            msgs.append("Error running VPR for {}:\n".format(split_dir_name[-2]) + out.stdout.decode("utf-8"))
            error |= 8

        return (verilog_file_name, i, error, msgs)
    except Exception as e:
        return (verilog_file_name, i, 16, ["Exception thrown: " + str(e)])


def launch_vpr(verilog_file_name, thread_pool):
    iters = int(sys.argv[1])
    output_prefix = sys.argv[3]
    odin_temp = output_prefix + "temp_" + verilog_file_name + "_odin"
    yosys_temp = output_prefix + "temp_" + verilog_file_name + "_yosys"

    errors = []
    processes = []
    for i in range(iters):
        error = 0
        msgs = []
        copy_command = "rm -r {0}_" + str(i) + "; cp -r {0} {0}_" + str(i)

        out = subprocess.run(copy_command.format(odin_temp), shell=True, stdout=subprocess.PIPE,
                             stderr=subprocess.STDOUT)
        if out.returncode != 0:
            msgs.append("Error copying Odin II output:\n" + out.stdout.decode("utf-8"))
            error |= 32

        out = subprocess.run(copy_command.format(yosys_temp), shell=True, stdout=subprocess.PIPE,
                             stderr=subprocess.STDOUT)
        if out.returncode != 0:
            msgs.append("Error copying Yosys output:\n" + out.stdout.decode("utf-8"))
            error |= 64

        if error == 0:
            line = "Launching VPR iteration " + str(i) + " for " + verilog_file_name
            print(line)
            print("="*len(line),"\n", flush=True)
            processes.append(thread_pool.apply_async(run_vpr, (odin_temp + "_" + str(i), i)))
            processes.append(thread_pool.apply_async(run_vpr, (yosys_temp + "_" + str(i), i)))

    cleanup_command = "rm -r {}"
    out = subprocess.run(cleanup_command.format(odin_temp), shell=True, stdout=subprocess.PIPE,
                         stderr=subprocess.STDOUT)
    if out.returncode != 0:
        print("WARNING: Failed to cleanup temporary directory {}\n".format(odin_temp) + out.stdout.decode("utf-8"), flush=True)

    out = subprocess.run(cleanup_command.format(yosys_temp), shell=True, stdout=subprocess.PIPE,
                         stderr=subprocess.STDOUT)
    if out.returncode != 0:
        print("WARNING: Failed to cleanup temporary directory {}".format(yosys_temp) + out.stdout.decode("utf-8"), flush=True)

    return processes, errors


def run_benchmarks(verilog_files):
    synthesis = {}
    vpr_runs = []
    threads = int(sys.argv[2])
    if threads <= 0:
        threads = multiprocessing.cpu_count()
    print("Running", threads, "parallel benchmarks", flush=True)
    manager = multiprocessing.Manager()
    queue = manager.Queue(len(verilog_files))
    with multiprocessing.Pool(threads) as thread_pool:
        for verilog_file in verilog_files:
            line = "Running synthesis for " + verilog_file
            print(line, flush=True)
            print("=" * len(line), "\n", flush=True)
            verilog_file_name = verilog_file.split("/")[-1]
            if verilog_file_name in synthesis.keys():
                print("ERROR: Duplicate names for Verilog file detected. Aborting.")
                print("Please ensure all input Verilog files have distinct names", flush=True)
                exit(1)
            synthesis[verilog_file_name] = thread_pool.apply_async(func=run_synthesis, args=(verilog_file, queue))

        print("Waiting for synthesis to complete")
        print("=================================\n", flush=True)

        errors = []
        for i in range(len(verilog_files)):
            verilog_file = queue.get()
            context = synthesis[verilog_file]
            res = context.get()
            line = "Finished synthesis for " + verilog_file
            if res[2] != 0:
                line += " with errors. Skipping VPR"
                errors.append(res)
            else:
                line += ". Starting VPR"

                procs, errs = launch_vpr(verilog_file, thread_pool)
                vpr_runs.extend(procs)
                errors.extend(errs)
            print(line)
            print("="*len(line), "\n", flush=True)

        print("All files synthesised. Waiting for VPR")
        print("======================================\n", flush=True)

        for res in vpr_runs:
            func_res = res.get()
            errors.append(func_res)

        print("All files completed. Exiting")
        print("============================\n", flush=True)
        return errors


errors = run_benchmarks(sys.argv[4:])
successes = {}
iters = int(sys.argv[1])
if errors != 0:
    for error in errors:
        if error[2] != 0:
            print(error[0], end=' ')
            if error[1] != -1:
                print("failed on VPR iteration", error[1], end=' ', flush=True)
            else:
                print("failed during synthesis", end=' ', flush=True)
            print("with error code", error[2], "giving the following messages:\n\n" + "\n\n".join(error[3]), flush=True)
        else:
            if error[0] not in successes.keys():
                successes[error[0]] = 0
            successes[error[0]] += 1
            if successes[error[0]] == iters * 2:
                print(error[0], "completed successfully\n", flush=True)
    exit(-1)
