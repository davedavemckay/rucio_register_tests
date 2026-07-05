import sys

times = []
file_count = 0

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