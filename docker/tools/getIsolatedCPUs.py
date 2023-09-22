#!/usr/bin/python3

import subprocess

def getIsolatedCPUs():
    cpus = []

    # Get list of CPU IDs
    cpu_list = []
    try:
        output = subprocess.check_output('cat /sys/devices/system/cpu/isolated', shell=True).strip().decode()
    except Exception as e:
        return []
    for cpu in output.split(','):
        if '-' in cpu: # This is a CPU range
            start, end = cpu.split('-')
            for idx in range(int(start), int(end)+1):
                cpus.append(idx)
        else: # This is an individual CPU
            cpus.append(cpu)

    return sorted(cpus)

if __name__ == '__main__':
    cpus = getIsolatedCPUs()
    for cpu in cpus:
        print(cpu, end=' ')
    print()
    exit(len(cpus))