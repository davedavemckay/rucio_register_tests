import os
import sys
from datetime import datetime

times = []
file_count = 0

using_autoregistration = False
using_autoregistration_finished = False
using_autoregistration_started = False

if len(sys.argv) > 1 and os.system('grep "Batch registration summary" ' + sys.argv[1] + '> /dev/null 2>&1') == 0:
    using_autoregistration = True

def batch_stats(filename=''):
    reg_summary_lines = []
    first_start_lines = {}
    
    with open(filename, 'r') as f:
        lines = f.readlines()
        for line in lines:
            if "Batch registration summary" in line:
                reg_summary_lines.append(line)
            elif ("Registering " in line or "Submitting " in line) and not ("Completed" in line or "summary" in line or "Done with" in line):
                # Extract dataset
                parts = line.split()
                dataset = None
                for part in parts:
                    if "Dataset/" in part:
                        dataset = part.strip().rstrip(':-').split('/')[-1]
                        break
                if dataset and dataset not in first_start_lines:
                    first_start_lines[dataset] = line
                    
    if len(reg_summary_lines) == 0 and using_autoregistration:
        raise ValueError("No batch registration summary lines found in the log file.")

    total_wall_time = 0
    total_cpu_time = 0
    batch_datasets = []
    batch_start_times = []
    batch_end_times = []
    batch_file_counts = []
    batch_failure_counts = []

    print(f"process_batch_lines: {len(first_start_lines)}; reg_summary_lines: {len(reg_summary_lines)}")

    for rs_line in reg_summary_lines:
        parts = rs_line.split()
        dataset = None
        for part in parts:
            if "Dataset/" in part:
                dataset = part.strip().rstrip(':-').split('/')[-1]
                break
                
        if not dataset:
            continue
            
        pb_line = first_start_lines.get(dataset)
        if not pb_line:
            continue
            
        batch_datasets.append(dataset)
        start_time = datetime.fromisoformat(' '.join(pb_line.split()[1:3]))
        end_time = datetime.fromisoformat(' '.join(rs_line.split()[1:3]))
        
        batch_start_times.append(start_time)
        batch_end_times.append(end_time)
        
        # print(f"Batch registration started at: {start_time}")
        # print(f"Batch registration finished at: {end_time}")
        
        total_cpu_time += (end_time - start_time).total_seconds()
        stats = rs_line.split(dataset)[1].strip(' - ').strip().split(', ')
        registered = 0
        failed = 0
        for stat in stats:
            if "registered" in stat:
                registered = int(stat.split(':')[1].strip())
            elif "failed" in stat:
                failed = int(stat.split(':')[1].strip())
                
        batch_file_counts.append(registered)
        batch_failure_counts.append(failed)

    chronological_batch_end_times = list(batch_end_times)
    chronological_batch_start_times = list(batch_start_times)
    chronological_batch_end_times.sort()
    chronological_batch_start_times.sort()

    if not chronological_batch_end_times or not chronological_batch_start_times:
        print("No matching batch start/end timestamps found.")
        return

    total_wall_time = (chronological_batch_end_times[-1] - chronological_batch_start_times[0]).total_seconds()
    file_count = sum(batch_file_counts)
    failures = sum(batch_failure_counts)
    registry_rate = float(file_count) / total_wall_time if total_wall_time > 0 else 0
    print("Registration stats.")
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