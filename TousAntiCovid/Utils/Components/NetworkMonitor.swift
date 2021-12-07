// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  NetworkMonitor.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 04/11/2021 - for the TousAntiCovid project.
//

import UIKit
import Network

@available(iOS 12, *)
protocol NetworkChangesObserver: AnyObject {
    func networkStateDidChange(isUnreachable: Bool, for reason: UnsatisfiedReason?)
}

@available(iOS 12, *)
protocol NetworkChangesManager: AnyObject {
    var isUnreachable: Bool { get }
    var unsatisfiedReason: UnsatisfiedReason? { get }
    func start()
    func stop()
    func addObserver(_ observer: NetworkChangesObserver)
    func removeObserver(_ observer: NetworkChangesObserver)
}

enum UnsatisfiedReason {
    case cellularDenied
    case wifiDenied
    case localNetworkDenied
}

@available(iOS 12, *)
final class NetworkMonitorObserverWrapper: NSObject {
    
    weak var observer: NetworkChangesObserver?
    
    init(observer: NetworkChangesObserver) {
        self.observer = observer
    }
    
}

@available(iOS 12, *)
final class NetworkMonitor: NetworkChangesManager {
    
    static let shared: NetworkMonitor = NetworkMonitor()
    
    var isUnreachable: Bool { status == .unreachable }
    var unsatisfiedReason: UnsatisfiedReason? {
        if #available(iOS 14.2, *) {
            switch monitor.currentPath.unsatisfiedReason {
            case .cellularDenied:
                return .cellularDenied
            case .wifiDenied:
                return .wifiDenied
            case .localNetworkDenied:
                return .localNetworkDenied
            default:
                return nil
            }
        } else {
            return nil
        }
    }
    
    private let monitor: NWPathMonitor = NWPathMonitor()
    private var observers: [NetworkMonitorObserverWrapper] = []
    private var lastKnownStatus: Status = .unreachable
    
    private var status: Status {
        guard monitor.currentPath.status == .satisfied else { return .unreachable }
        if monitor.currentPath.usesInterfaceType(.wifi) {
            return .wifi
        } else if monitor.currentPath.usesInterfaceType(.cellular) {
            return .cellular
        } else if monitor.currentPath.usesInterfaceType(.wiredEthernet) {
            return .wiredEthernet
        } else {
            return .unknown
        }
    }
    
    func start() {
        monitor.pathUpdateHandler = { _ in
            if self.status != self.lastKnownStatus {
                self.lastKnownStatus = self.status
                DispatchQueue.main.async {
                    self.notifyObservers()
                }
            }
        }
        monitor.start(queue: DispatchQueue.global(qos: .background))
    }
    
    func stop() {
        monitor.cancel()
    }
    
    func addObserver(_ observer: NetworkChangesObserver) {
        guard observerWrapper(for: observer) == nil else { return }
        observers.append(NetworkMonitorObserverWrapper(observer: observer))
    }
    
    func removeObserver(_ observer: NetworkChangesObserver) {
        guard let wrapper = observerWrapper(for: observer), let index = observers.firstIndex(of: wrapper) else { return }
        observers.remove(at: index)
    }
    
    private func observerWrapper(for observer: NetworkChangesObserver) -> NetworkMonitorObserverWrapper? {
        observers.first { $0.observer === observer }
    }
    
    private func notifyObservers() {
        observers.forEach { $0.observer?.networkStateDidChange(isUnreachable: status == .unreachable, for: unsatisfiedReason) }
    }
    
}

@available(iOS 12, *)
private extension NetworkMonitor {
    enum Status: String {
        case wifi = "Wi-Fi"
        case cellular = "Cellular"
        case wiredEthernet = "Wired Ethernet"
        case unreachable = "Unreachable"
        case unknown = "Unknown"
    }
}
