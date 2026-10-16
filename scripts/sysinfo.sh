#!/usr/bin/env bash

# System Information Report
# Usage: ./system_report.sh

set -u

print_section() {
    echo
    echo "========================================"
    echo " $1"
    echo "========================================"
}

# Hostname
print_section "HOSTNAME"
hostname

# Operating System and Kernel
print_section "OPERATING SYSTEM / KERNEL"

if [[ -r /etc/os-release ]]; then
    . /etc/os-release
    echo "OS: ${PRETTY_NAME:-Unknown}"
elif [[ "$(uname -s)" == "Darwin" ]]; then
    echo "OS: $(sw_vers -productName) $(sw_vers -productVersion)"
else
    echo "OS: $(uname -s)"
fi

echo "Kernel: $(uname -sr)"
echo "Architecture: $(uname -m)"

# CPU Information
print_section "CPU INFORMATION"

if [[ -r /proc/cpuinfo ]]; then
    grep -m 1 -E 'model name|Hardware' /proc/cpuinfo \
        | cut -d ':' -f 2- \
        | sed 's/^[[:space:]]*//'
    echo "Logical CPUs: $(grep -c '^processor' /proc/cpuinfo)"
elif [[ "$(uname -s)" == "Darwin" ]]; then
    echo "CPU: $(sysctl -n machdep.cpu.brand_string 2>/dev/null || echo "Unknown")"
    echo "Logical CPUs: $(sysctl -n hw.logicalcpu)"
else
    echo "CPU: Not available"
fi

# Memory Usage
print_section "MEMORY USAGE"

if [[ "$(uname -s)" == "Linux" ]] && command -v free >/dev/null 2>&1; then
    free -h
elif [[ "$(uname -s)" == "Darwin" ]]; then
    echo "Total memory: $(sysctl -n hw.memsize | awk '{printf "%.2f GiB\n", $1/1073741824}')"
    vm_stat
else
    echo "Memory information is unavailable on this system."
fi

# Disk Usage
print_section "DISK USAGE"
df -h -P

# System Uptime
print_section "SYSTEM UPTIME"
uptime

# Report Timestamp
print_section "REPORT GENERATED"
date

echo
echo "System information report completed."
