import os
import sys

times = []
file_count = 0

using_autoregistration = False

if os.system('grep "Auto-registration summary" ' + sys.argv[1] + '> /dev/null 2>&1') == 0:
    using_autoregistration = True

if not using_autoregistration:
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

else:
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
                    elif "Registrations per second" in stat:
                        registry_rate = float(stat.split(':')[1].strip().split()[0])
                        break

    print(f"Total time taken: {total_time:.6f} seconds")
    print(f"Files registered: {file_count}")
    print(f"Registration rate: {registry_rate:.2f} Hz (files/second)")