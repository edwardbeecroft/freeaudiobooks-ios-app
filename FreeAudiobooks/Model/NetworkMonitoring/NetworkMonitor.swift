//
//  NetworkMonitor.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 03/10/2025.
//  Copyright © 2025 FreeAudiobooks Technologies. All rights reserved.
//

import Foundation
import Network

/// Monitors network connectivity status using NWPathMonitor
class NetworkMonitor {
    static let shared = NetworkMonitor()

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.freebooks.networkmonitor")

    /// Current network connectivity status
    private(set) var isConnected: Bool = true

    var isConnectedNow: Bool {
        return Reachability.isConnectedToNetwork()
    }

    /// Notification posted when connectivity status changes
    static let connectivityChangedNotification = Notification.Name("NetworkMonitorConnectivityChanged")

    private init() {}

    deinit {
        stopMonitoring()
    }

    func startMonitoring() {
        // Get initial state immediately (synchronously)
        let initialPath = monitor.currentPath
        isConnected = initialPath.status != .unsatisfied
        print("Network Monitoring: Initial state -> \(isConnected)")

        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }

            // Check if path is NOT unsatisfied (includes .satisfied and .requiresConnection)
            self.isConnected = path.status != .unsatisfied
            print("Network Monitoring: Is connected -> \(self.isConnected)")

            // Always post notification with current status - let consumers decide if they need to act
            print("Network Monitoring: Posting notification")
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: NetworkMonitor.connectivityChangedNotification,
                    object: nil,
                    userInfo: ["isConnected": self.isConnected]
                )
            }
        }

        monitor.start(queue: queue)
    }

    private func stopMonitoring() {
        monitor.cancel()
    }
}
