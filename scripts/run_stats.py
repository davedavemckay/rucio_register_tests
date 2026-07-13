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


if using_autoregistration_finished:
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

elif using_autoregistration_started:

    reg_summary_lines = []
    process_batch_lines = []
    with open(sys.argv[1], 'r') as f:
        lines = f.readlines()
        for line in lines:
            if "Batch registration summary" in line:
                reg_summary_lines.append(line)
            elif "process_batch" in line:
                process_batch_lines.append(line)
    file_count = 0
    failures = 0
    total_wall_time = 0
    total_cpu_time = 0
    first_start_time = None
    last_end_time = None

    for rs_line in reg_summary_lines:
        dataset = rs_line.split()[-6].strip()
        for pb_line in process_batch_lines:
            if dataset in pb_line and "process_batch" in pb_line:       
                batch_start_time = datetime.fromisoformat(' '.join(pb_line.split()[1:3]))
                if first_start_time is None or batch_start_time < first_start_time:
                    first_start_time = batch_start_time
                print(f"Batch registration started at: {batch_start_time}")
                batch_end_time = datetime.fromisoformat(' '.join(rs_line.split()[1:3]))
                if last_end_time is None or batch_end_time > last_end_time:
                    last_end_time = batch_end_time
                print(f"Batch registration finished at: {batch_end_time}")
                total_cpu_time += (batch_end_time - batch_start_time).total_seconds()
                stats = rs_line.split(dataset)[1].strip(' - ').strip().split(', ')
                for stat in stats:
                    if "registered" in stat:
                        file_count += int(stat.split(':')[1].strip())
                    elif "failed" in stat:
                        failures += int(stat.split(':')[1].strip())
                        break
    print(f"First batch registration started at: {first_start_time}")
    print(f"Last batch registration finished at: {last_end_time}")
    assert isinstance(first_start_time, datetime) and isinstance(last_end_time, datetime), "First and last batch start and end times must be datetime objects"
    total_wall_time = (last_end_time - first_start_time).total_seconds()
    assert isinstance(batch_start_time, datetime) and isinstance(batch_end_time, datetime), "Batch start and end times must be datetime objects"
    
    registry_rate = float(file_count) / total_wall_time if total_wall_time > 0 else 0
    print("In-progress registration stats.")
    print(f"Total walltime: {total_wall_time:.6f} seconds")
    print(f"Total cputime: {total_cpu_time:.6f} seconds")
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