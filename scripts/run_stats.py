import os
import sys
from datetime import datetime

times = []
file_count = 0

using_autoregistration_finished = False
using_autoregistration_started = False

if os.system('grep "Auto-registration summary" ' + sys.argv[1] + '> /dev/null 2>&1') == 0:
    using_autoregistration_finished = True
elif os.system('grep "Batch registration summary" ' + sys.argv[1] + '> /dev/null 2>&1') == 0:
    using_autoregistration_started = True

def batch_stats(filename=''):
    reg_summary_lines = []
    process_batch_lines = []
    with open(filename, 'r') as f:
        lines = f.readlines()
        for line in lines:
            if "Batch registration summary" in line:
                reg_summary_lines.append(line)
            elif "process_batch" in line:
                process_batch_lines.append(line)
    if len(reg_summary_lines) == 0 and using_autoregistration_started:
        raise ValueError("No batch registration summary lines found in the log file.")
    if len(process_batch_lines) == 0 and using_autoregistration_finished:
        raise ValueError("No process_batch lines found in the log file.")

    total_wall_time = 0
    total_cpu_time = 0
    batch_datasets = []
    batch_start_times = []
    batch_end_times = []
    batch_file_counts = []
    batch_failure_counts = []


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
    chronological_batch_end_times = copy(batch_end_times)
    chronological_batch_start_times = copy(batch_start_times)
    chronological_batch_end_times.sort()
    chronological_batch_start_times.sort()

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

if using_autoregistration_started or using_autoregistration_finished:
    try:
        batch_stats(sys.argv[1])
    except ValueError as e:
        print(f"Error: {e}")
        if using_autoregistration_finished:
            total_time = 0
            failures = 0
            registry_rate = 0
            with open(sys.argv[1], 'r') as f:
                lines = f.readlines()
                for line in lines:
                    if "Auto-registration summary" in line:
                        stats = line.split('Auto-registration summary')[1].strip(' - ').split('|')
                        for stat in stats:
                            if "Total" in stat:
                                if "time" in stat:
                                    total_time = float(stat.split(':')[1].strip().split()[0])
                                elif "files registered" in stat:
                                    file_count = int(stat.split(':')[1].strip())
                                elif "registration failures" in stat:
                                    failures = int(stat.split(':')[1].strip())
                            elif "Registrations per second" in stat:
                                registry_rate = float(stat.split(':')[1].strip().split()[0])
                                break
            print(f"Total time taken: {total_time:.6f} seconds")
            print(f"Files registered: {file_count}")
            print(f"Failures: {failures}")
            print(f"Registration rate: {registry_rate:.2f} Hz (files/second)")
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