import Foundation
import ServiceManagement

if CommandLine.arguments.count <= 3 {
    print("Usage: \(CommandLine.arguments[0]) register|unregister|status agent|daemon <plist name>")
    exit(2)
}

let command = CommandLine.arguments[1]
let agentOrDaemon = CommandLine.arguments[2]
let plistName = CommandLine.arguments[3]

let service: SMAppService
switch agentOrDaemon {
case "agent":
    service = SMAppService.agent(plistName: plistName)
case "daemon":
    service = SMAppService.daemon(plistName: plistName)
default:
    print("2nd argument must be one of: agent, daemon")
    exit(2)
}

switch command {
case "register":
    do {
        try service.register()
        print("Successfully registered \(agentOrDaemon) \(plistName)")
    } catch {
        print("Unable to register \(agentOrDaemon) \(plistName) with error: \(error)")
        exit(1)
    }
case "unregister":
    do {
        try service.unregister()
        print("Successfully unregistered \(agentOrDaemon) \(plistName)")
    } catch {
        print("Unable to unregister \(agentOrDaemon) \(plistName) with error: \(error)")
        exit(1)
    }
case "status":
    switch service.status {
    case .notRegistered:
        // Confusingly, the docs say that this case can also happen when the service has been double-registered.
        print("\(agentOrDaemon) \(plistName) is not yet registered")
    case .enabled:
        print("\(agentOrDaemon) \(plistName) has been registered")
    case .requiresApproval:
        print("\(agentOrDaemon) \(plistName) must be approved in System Preferences")
    case .notFound:
        print("\(agentOrDaemon) \(plistName) cannot be found")
    @unknown default:
        print("\(agentOrDaemon) \(plistName) is in an unknown state")
    }
default:
    print("1st argument must be one of: register, unregister, status")
    exit(2)
}
