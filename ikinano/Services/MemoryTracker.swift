//
//  MemoryTracker.swift
//  ikinano
//

import Foundation

class MemoryTracker {
    static func getCurrentMemoryUsageMB() -> Int64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4

        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(
                    mach_task_self_,
                    task_flavor_t(MACH_TASK_BASIC_INFO),
                    $0,
                    &count
                )
            }
        }

        if kerr == KERN_SUCCESS {
            return Int64(info.resident_size) / 1024 / 1024
        }
        return 0
    }

    static func getPeakMemoryMB() -> Int64 {
        return Int64(ProcessInfo.processInfo.physicalMemory) / 1024 / 1024
    }

    static func getTotalSystemMemoryMB() -> Int64 {
        return Int64(ProcessInfo.processInfo.physicalMemory) / 1024 / 1024
    }
}
