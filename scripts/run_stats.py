import os
import sys
from datetime import datetime

times = []
file_count = 0

using_autoregistration_finished = False
using_autoregistration_started = False

if os.system('grep "Batch registration summary" ' + sys.argv[1] + '> /dev/null 2>&1') == 0:
    using_autoregistration = True

def batch_stats(filename=''):
    reg_summary_lines = []
    process_batch_lines = []
    this_dataset = ''
    with open(filename, 'r') as f:
        lines = f.readlines()
        for line in lines:
            if "Batch registration summary" in line:
                reg_summary_lines.append(line)
                this_dataset = reg_summary_lines[-1].split()[-6].strip().split('/')[-1].strip()
            elif this_dataset in line and "Submitting registration batch for" in line:
                process_batch_lines.append(line)
    if len(reg_summary_lines) == 0 and using_autoregistration:
        raise ValueError("No batch registration summary lines found in the log file.")

    total_wall_time = 0
    total_cpu_time = 0
    batch_datasets = []
    batch_start_times = []
    batch_end_times = []
    batch_file_counts = []
    batch_failure_counts = []

    print(f"process_batch_lines: {len(process_batch_lines)}; reg_summary_lines: {len(reg_summary_lines)}")


    for rs_line in reg_summary_lines:
        dataset = rs_line.split()[-6].strip().split('/')[-1].strip()
        batch_datasets.append(dataset)
        for pb_line in process_batch_lines:
            if dataset in pb_line and "process_batch" in pb_line:       
                batch_start_times.append(datetime.fromisoformat(' '.join(pb_line.split()[1:3])))
                # print(f"Batch registration started at: {batch_start_times[-1]}")
                batch_end_times.append(datetime.fromisoformat(' '.join(rs_line.split()[1:3])))
                # print(f"Batch registration finished at: {batch_end_times[-1]}")
                total_cpu_time += (batch_end_times[-1] - batch_start_times[-1]).total_seconds()
                stats = rs_line.split(dataset)[1].strip(' - ').strip().split(', ')
                for stat in stats:
                    if "registered" in stat:
                        batch_file_counts.append(int(stat.split(':')[1].strip()))
                    elif "failed" in stat:
                        batch_failure_counts.append(int(stat.split(':')[1].strip()))
                print(f"Batch stats: dataset: {dataset}; "\
                    f"file count: {batch_file_counts[-1]}; "\
                    f"failure count: {batch_failure_counts[-1]}; "\
                    f"start time: {batch_start_times[-1]}; "\
                    f"end time: {batch_end_times[-1]}; "\
                    f"batch time: {batch_end_times[-1] - batch_start_times[-1]}; "\
                    f"registration rate: {batch_file_counts[-1] / (batch_end_times[-1] - batch_start_times[-1]).total_seconds() if (batch_end_times[-1] - batch_start_times[-1]).total_seconds() > 0 else 0:.2f} Hz")
    chronological_batch_end_times = list(batch_end_times)
    chronological_batch_start_times = list(batch_start_times)
    chronological_batch_end_times.sort()
    chronological_batch_start_times.sort()
    print(chronological_batch_end_times, chronological_batch_start_times)

    total_wall_time = (chronological_batch_end_times[-1] - chronological_batch_start_times[0]).total_seconds()
    file_count = sum(batch_file_counts)
    failures = sum(batch_failure_counts)
    registry_rate = float(file_count) / total_wall_time if total_wall_time > 0 else 0
    print("In-progress registration stats.")
    print(f"Total walltime: {total_wall_time:.6f} seconds")
    print(f"Total cputime: {total_cpu_time:.6f} seconds")
    print(f"Files registered: {file_count}")
    print(f"Failures: {failures}")
    print(f"Registration rate: {registry_rate:.2f} Hz (files/second)")

if using_autoregistration:
    try:
        batch_stats(sys.argv[1])
    except ValueError as e:
        print(f"Error: {e}")

else:
    with open(sys.argv[1], 'r') as f:
        lines = f.readlines()
        for line in lines:
            if line.startswith('Time:'):
                times.append(line.split()[1].strip())
            elif line.startswith('File count:'):
                file_count = int(line.split()[2].strip())

    time_delta = float(times[-1]) - float(times[0])
    print(f"Total time taken: {time_delta:.6f} seconds")

    print(f"Files registered: {file_count}")

    registry_rate = float(file_count) / time_delta if time_delta > 0 else 0
    print(f"Registration rate: {registry_rate:.2f} Hz (files/second)")