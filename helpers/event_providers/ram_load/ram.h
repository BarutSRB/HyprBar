#pragma once
#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <sys/sysctl.h>
#include <mach/mach.h>
#include <mach/mach_host.h>

struct ram {
    uint64_t total_memory;  // Total RAM in bytes
    uint64_t used_memory;   // Used RAM in bytes
    int used_percentage;    // Used RAM percentage
    double used_gb;         // Used RAM in GB
    double total_gb;        // Total RAM in GB
};

static inline void ram_init(struct ram* ram) {
    // Get total physical memory
    int mib[2] = {CTL_HW, HW_MEMSIZE};
    size_t length = sizeof(ram->total_memory);
    sysctl(mib, 2, &ram->total_memory, &length, NULL, 0);
    ram->total_gb = (double)ram->total_memory / (1024.0 * 1024.0 * 1024.0);
}

static inline void ram_update(struct ram* ram) {
    // Get VM statistics
    vm_size_t page_size;
    vm_statistics64_data_t vm_stat;
    mach_msg_type_number_t host_size = sizeof(vm_stat) / sizeof(natural_t);
    
    host_page_size(mach_host_self(), &page_size);
    host_statistics64(mach_host_self(), HOST_VM_INFO64, (host_info64_t)&vm_stat, &host_size);
    
    // Calculate used memory
    // Used = Active + Wired + Compressed
    uint64_t used_pages = vm_stat.active_count + vm_stat.wire_count + vm_stat.compressor_page_count;
    ram->used_memory = used_pages * page_size;
    
    // Calculate percentage and GB
    ram->used_percentage = (int)((double)ram->used_memory / (double)ram->total_memory * 100.0);
    ram->used_gb = (double)ram->used_memory / (1024.0 * 1024.0 * 1024.0);
    
    // Ensure percentage is within bounds
    if (ram->used_percentage > 100) ram->used_percentage = 100;
    if (ram->used_percentage < 0) ram->used_percentage = 0;
}