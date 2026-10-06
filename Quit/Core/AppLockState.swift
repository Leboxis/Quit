import Foundation
import SwiftUI

/// Only the current foreground authentication may unlock the personal space.
struct AppLockState {
    private(set) var unlocked = false
    private var request: UUID?
    private var awaitingActivation = false

    var authenticating: Bool { request != nil }

    mutating func beginAuthentication() -> UUID? {
        guard request == nil else { return nil }
        let token = UUID()
        request = token
        awaitingActivation = false
        return token
    }

    mutating func sceneChanged(to phase: ScenePhase) {
        switch phase {
        case .active:
            if awaitingActivation { unlocked = true }
            awaitingActivation = false
        case .inactive:
            unlocked = false
        case .background:
            unlocked = false
            awaitingActivation = false
            request = nil
        @unknown default:
            unlocked = false
            awaitingActivation = false
            request = nil
        }
    }

    @discardableResult
    mutating func finishAuthentication(_ token: UUID, succeeded: Bool, phase: ScenePhase) -> Bool {
        guard request == token else { return false }
        request = nil
        unlocked = succeeded && phase == .active
        // The system authentication prompt can temporarily make the scene inactive.
        awaitingActivation = succeeded && phase == .inactive
        return true
    }
}
