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
            if "Auto-reg" in line:
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
    with open(sys.argv[1], 'r') as f:
        lines = f.readlines()
        for line in lines:
            if "Batch registration summary" in line:
                reg_summary_lines.append(line)
    for rs_line in reg_summary_lines:
        dataset = rs_line.split()[-6].strip()
        with open(sys.argv[1], 'r') as f:
            lines = f.readlines()
            for line in lines:
                if dataset in line and "process_batch" in line:       
                    batch_start_time = datetime.fromisoformat(' '.join(line.split()[1:3]))
                    print(f"Batch registration started at: {batch_start_time}")
                    batch_end_time = datetime.fromisoformat(' '.join(rs_line.split()[1:3]))
                    print(f"Batch registration finished at: {batch_end_time}")
                    stats = rs_line.split(dataset)[1].strip(' - ').split(', ')
                    for stat in stats:
                        if "registered" in stat:
                            file_count = int(stat.split(':')[1].strip())
                        elif "failed" in stat:
                            failures = int(stat.split(':')[1].strip())
                            break
    assert isinstance(batch_start_time, datetime) and isinstance(batch_end_time, datetime), "Batch start and end times must be datetime objects"
    time_delta = (batch_end_time - batch_start_time).total_seconds()
    registry_rate = float(file_count) / time_delta if time_delta > 0 else 0
    print(f"Total time taken: {time_delta:.6f} seconds")
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