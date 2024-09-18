#!/bin/bash

OUTPUT_DIR="system_info_$(hostname)"
mkdir -p "$OUTPUT_DIR"

# Kernel Information
uname -a > "$OUTPUT_DIR/uname.txt"
cat /proc/version > "$OUTPUT_DIR/proc_version.txt"

# Boot Parameters
cat /proc/cmdline > "$OUTPUT_DIR/proc_cmdline.txt"

# Scheduler Settings
cat /proc/sys/kernel/sched_* > "$OUTPUT_DIR/sched_sysctl.txt"
cat /sys/kernel/debug/sched_features > "$OUTPUT_DIR/sched_features.txt" 2>/dev/null

# CPU Frequency Scaling
cpupower frequency-info > "$OUTPUT_DIR/cpupower_frequency_info.txt"
for cpu in /sys/devices/system/cpu/cpu[0-9]*; do
  echo "${cpu##*/}" >> "$OUTPUT_DIR/cpu_governors.txt"
  cat "$cpu/cpufreq/scaling_governor" >> "$OUTPUT_DIR/cpu_governors.txt"
done

# smp_affinity
grep . /proc/irq/*/smp_affinity_list > "$OUTPUT_DIR/smp_affinity_list.txt"

# NUMA Configuration
numactl --hardware > "$OUTPUT_DIR/numa_hardware.txt"
numactl --show > "$OUTPUT_DIR/numa_policy.txt"

# Hyper-Threading Status
lscpu -e > "$OUTPUT_DIR/lscpu.txt"

# Kernel Config
grep PREEMPT /boot/config-$(uname -r) > "$OUTPUT_DIR/kernel_preempt.txt"
grep CONFIG_HZ /boot/config-$(uname -r) > "$OUTPUT_DIR/kernel_hz.txt"

# SELinux Status
sestatus > "$OUTPUT_DIR/selinux_status.txt"

# Packages and Modules
rpm -qa | sort > "$OUTPUT_DIR/installed_packages.txt"
lsmod > "$OUTPUT_DIR/loaded_modules.txt"

# Interrupts
cat /proc/interrupts > "$OUTPUT_DIR/interrupts.txt"

# Save the script and make it executable
chmod +x collect_system_info.sh
