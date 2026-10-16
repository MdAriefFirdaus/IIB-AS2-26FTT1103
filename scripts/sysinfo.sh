#!/usr/bin/env bash

# ==========================================
# System Information Report
# Features:
# - Hostname and OS/kernel information
# - CPU information and load averages
# - Memory and disk usage
# - System uptime
# - Timestamped logging
# - Save reports in the logs/ directory
# ==========================================

set -u
umask 077

# Configuration
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="${SCRIPT_DIR}/logs"
TIMESTAMP="$(date '+%Y-%m-%d_%H-%M-%S')"
LOG_FILE="${LOG_DIR}/system_report_${TIMESTAMP}.log"

# Create log directory
if ! mkdir -p "$LOG_DIR"; then
    echo "ERROR: Cannot create log directory: $LOG_DIR" >&2
    exit 1
fi

# Send output to both terminal and log file
if ! touch "$LOG_FILE"; then
    echo "ERROR: Cannot create log file: $LOG_FILE" >&2
    exit 1
fi

exec > >(tee -a "$LOG_FILE") 2>&1

print_section() {
    echo
    echo "=========================================="
    echo " $1"
    echo "=========================================="
}

get_os() {
    if [[ -r /etc/os-release ]]; then
        . /etc/os-release
        echo "${PRETTY_NAME:-Unknown}"
    elif [[ "$(uname -s)" == "Darwin" ]]; then
        sw_vers -productName
        sw_vers -productVersion
    else
        uname -s
    fi
}

echo "SYSTEM INFORMATION REPORT"
echo "Generated: $(date '+%Y-%m-%d %H:%M:%S %Z')"
echo "Log file: $LOG_FILE"

# Hostname
print_section "HOSTNAME"
hostname

# Operating system and kernel
print_section "OPERATING SYSTEM / KERNEL"
echo "OS: $(get_os)"
echo "Kernel: $(uname -sr)"
echo "Architecture: $(uname -m)"

# CPU information
print_section "CPU INFORMATION"

if [[ -r /proc/cpuinfo ]]; then
    CPU_MODEL="$(awk -F ': ' \
        '/model name|Hardware/ {print $2; exit}' /proc/cpuinfo)"
    CPU_COUNT="$(grep -c '^processor' /proc/cpuinfo || true)"

    echo "CPU model: ${CPU_MODEL:-Unknown}"
    echo "Logical CPUs: ${CPU_COUNT:-Unknown}"

elif [[ "$(uname -s)" == "Darwin" ]]; then
    echo "CPU model: $(sysctl -n machdep.cpu.brand_string 2>/dev/null || echo Unknown)"
    echo "Logical CPUs: $(sysctl -n hw.logicalcpu 2>/dev/null || echo Unknown)"
else
    echo "CPU details unavailable."
fi

# CPU load
print_section "CPU LOAD"

if [[ -r /proc/loadavg ]]; then
    read -r LOAD1 LOAD5 LOAD15 _ < /proc/loadavg
    echo "Load average (1 min):  $LOAD1"
    echo "Load average (5 min):  $LOAD5"
    echo "Load average (15 min): $LOAD15"
elif command -v uptime >/dev/null 2>&1; then
    uptime
else
    echo "CPU load unavailable."
fi

# Memory usage
print_section "MEMORY USAGE"

if command -v free >/dev/null 2>&1; then
    free -h
elif [[ "$(uname -s)" == "Darwin" ]]; then
    echo "Total memory:"
    sysctl -n hw.memsize |
        awk '{printf "%.2f GiB\n", $1 / 1073741824}'
    echo
    echo "Virtual memory statistics:"
    vm_stat
else
    echo "Memory information unavailable."
fi

# Disk usage
print_section "DISK USAGE"
df -h -P

# System uptime
print_section "SYSTEM UPTIME"
uptime

# Logged-in users
print_section "LOGGED-IN USERS"

if command -v who >/dev/null 2>&1; then
    who
else
    echo "User information unavailable."
fi

# Network information (best effort)
print_section "NETWORK INFORMATION"

if command -v hostname >/dev/null 2>&1; then
    echo "Hostname: $(hostname)"
fi

if command -v ip >/dev/null 2>&1; then
    ip -brief address 2>/dev/null || echo "IP details unavailable."
elif command -v ifconfig >/dev/null 2>&1; then
    ifconfig 2>/dev/null || echo "Network details unavailable."
else
    echo "Network utility not found."
fi

# Report completion
print_section "REPORT SUMMARY"
echo "Status: Completed"
echo "Finished: $(date '+%Y-%m-%d %H:%M:%S %Z')"
echo "Saved to: $LOG_FILE"
echo
echo "System report completed successfully."
