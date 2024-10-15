//
//  NetworkServiceDiscovery.swift
//  rawDataiOSAppAcquisition
//
//  Created by Irnu Suryohadi Kusumo on 15.10.24.
//

import Foundation

class NetworkServiceDiscovery: NSObject, NetServiceBrowserDelegate, NetServiceDelegate {
    var netServiceBrowser: NetServiceBrowser?
    var discoveredService: NetService?

    func discoverService() {
        netServiceBrowser = NetServiceBrowser()
        netServiceBrowser?.delegate = self
        netServiceBrowser?.searchForServices(ofType: "_http._tcp", inDomain: "local.") // Service type for HTTP
    }

    // Called when a service is found
    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        discoveredService = service
        service.delegate = self
        service.resolve(withTimeout: 5.0) // Try to resolve the service to get its IP address
    }

    // Called when the service has been resolved (IP address found)
    func netServiceDidResolveAddress(_ sender: NetService) {
        if let ipAddress = resolveIPAddress(from: sender) {
            print("Discovered service IP address: \(ipAddress)")
            let serverURLString = "http://\(ipAddress):\(sender.port)"
            if let serverURL = URL(string: serverURLString) {
                healthKitManager.saveDataAsCSV(serverURL: serverURL)
            }
        }
    }

    // Helper function to resolve the IP address from a NetService
    func resolveIPAddress(from service: NetService) -> String? {
        guard let addresses = service.addresses else { return nil }

        for addressData in addresses {
            let address = addressData.withUnsafeBytes { (pointer: UnsafeRawBufferPointer) -> sockaddr_in in
                pointer.load(as: sockaddr_in.self)
            }
            if address.sin_family == __uint8_t(AF_INET) {
                var ipAddress = [CChar](repeating: 0, count: Int(INET_ADDRSTRLEN))
                inet_ntop(AF_INET, &address.sin_addr, &ipAddress, socklen_t(INET_ADDRSTRLEN))
                return String(cString: ipAddress)
            }
        }
        return nil
    }
}
