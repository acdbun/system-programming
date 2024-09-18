#!/bin/bash

# Collect Kernel and CPU Information Script
# Usage: ./collect_kernel_cpu_info.sh

OUTPUT_FILE="kernel_cpu_info_$(hostname).txt"

echo "Collecting kernel and CPU information..."

{
    echo "=== System Information ==="
    echo "Hostname: $(hostname)"
    echo "Date: $(date)"
    echo

    echo "=== Kernel Version ==="
    uname -a
    echo

    echo "=== Kernel Boot Parameters ==="
    cat /proc/cmdline
    echo

    echo "=== Kernel Preemption Model ==="
    if [ -f /boot/config-$(uname -r) ]; then
        echo "From /boot/config-$(uname -r):"
        grep PREEMPT /boot/config-$(uname -r)
    else
        echo "/boot/config-$(uname -r) not found. Trying /proc/config.gz..."
        if [ -f /proc/config.gz ]; then
            zcat /proc/config.gz | grep PREEMPT
        else
            echo "Kernel config not found."
        fi
    fi
    echo

    echo "=== Kernel Timer Frequency ==="
    if [ -f /boot/config-$(uname -r) ]; then
        grep CONFIG_HZ /boot/config-$(uname -r)
    else
        echo "Kernel config not found."
    fi
    echo

    echo "=== CPU Frequency Scaling Governors ==="
    for cpu in /sys/devices/system/cpu/cpu[0-9]*; do
        cpu_num=${cpu##*/cpu}
        scaling_governor_file="$cpu/cpufreq/scaling_governor"
        scaling_driver_file="$cpu/cpufreq/scaling_driver"
        if [ -f "$scaling_governor_file" ]; then
            echo "CPU$cpu_num Scaling Governor: $(cat $scaling_governor_file)"
        else
            echo "CPU$cpu_num Scaling Governor: Not available"
        fi
        if [ -f "$scaling_driver_file" ]; then
            echo "CPU$cpu_num Scaling Driver: $(cat $scaling_driver_file)"
        else
            echo "CPU$cpu_num Scaling Driver: Not available"
        fi
        echo
    done
    echo

    echo "=== Available CPU Frequency Scaling Governors ==="
    if [ -f /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors ]; then
        cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors
    else
        echo "Not available"
    fi
    echo

    echo "=== Scheduler Settings ==="
    echo "Scheduler Migration Cost (ns): $(cat /proc/sys/kernel/sched_migration_cost_ns)"
    echo "Scheduler Minimum Granularity (ns): $(cat /proc/sys/kernel/sched_min_granularity_ns)"
    echo "Scheduler Latency (ns): $(cat /proc/sys/kernel/sched_latency_ns)"
    echo "Scheduler Wakeup Granularity (ns): $(cat /proc/sys/kernel/sched_wakeup_granularity_ns)"
    echo

    echo "=== Scheduler Features ==="
    if [ -f /sys/kernel/debug/sched_features ]; then
        cat /sys/kernel/debug/sched_features
    else
        echo "/sys/kernel/debug/sched_features not available. Mounting debugfs..."
        sudo mount -t debugfs none /sys/kernel/debug
        if [ -f /sys/kernel/debug/sched_features ]; then
            cat /sys/kernel/debug/sched_features
        else
            echo "Unable to access /sys/kernel/debug/sched_features"
        fi
    fi
    echo

    echo "=== CPU Topology ==="
    lscpu
    echo

    echo "=== Interrupt Affinity Settings ==="
    echo "smp_affinity_list for all IRQs:"
    grep . /proc/irq/*/smp_affinity_list
    echo

    echo "=== CPU Frequency Scaling Settings ==="
    for cpu in /sys/devices/system/cpu/cpu[0-9]*; do
        cpu_num=${cpu##*/cpu}
        echo "CPU$cpu_num Maximum Frequency: $(cat $cpu/cpufreq/scaling_max_freq 2>/dev/null || echo 'N/A')"
        echo "CPU$cpu_num Minimum Frequency: $(cat $cpu/cpufreq/scaling_min_freq 2>/dev/null || echo 'N/A')"
        echo
    done
    echo

    echo "=== Kernel Modules Loaded ==="
    lsmod
    echo

    echo "=== SELinux Status ==="
    if command -v getenforce >/dev/null 2>&1; then
        echo "SELinux mode: $(getenforce)"
    else
        echo "getenforce command not found."
    fi
    echo

    echo "=== Kernel Command Line Parameters ==="
    cat /proc/cmdline
    echo

    echo "=== CPU Idle States ==="
    for cpu in /sys/devices/system/cpu/cpu[0-9]*; do
        cpu_num=${cpu##*/cpu}
        echo "CPU$cpu_num Idle States:"
        if [ -d "$cpu/cpuidle" ]; then
            for state in "$cpu"/cpuidle/state[0-9]*; do
                state_num=${state##*/state}
                state_name=$(cat "$state/name")
                echo "  State$state_num: $state_name"
                echo "    Usage: $(cat "$state/usage")"
            done
        else
            echo "  CPU idle states not available."
        fi
        echo
    done
    echo

    echo "=== NUMA Configuration ==="
    if command -v numactl >/dev/null 2>&1; then
        numactl --hardware
    else
        echo "numactl command not found."
    fi
    echo

    echo "=== Hyper-Threading Status ==="
    echo "CPU cores and siblings:"
    for cpu in /sys/devices/system/cpu/cpu[0-9]*; do
        cpu_num=${cpu##*/cpu}
        if [ -f "$cpu/topology/thread_siblings_list" ]; then
            echo "CPU$cpu_num Thread Siblings: $(cat $cpu/topology/thread_siblings_list)"
        fi
    done
    echo

    echo "=== Kernel Scheduler Statistics ==="
    if [ -f /proc/schedstat ]; then
        cat /proc/schedstat
    else
        echo "/proc/schedstat not available."
    fi
    echo

    echo "=== Scheduler Policies for Running Processes ==="
    ps -eo pid,comm,policy,pri,nice | sort -k3
    echo

    echo "=== CPU Frequency Information ==="
    if command -v cpupower >/dev/null 2>&1; then
        cpupower frequency-info
    else
        echo "cpupower command not found."
    fi
    echo

} > "$OUTPUT_FILE"

echo "Information collected in $OUTPUT_FILE"