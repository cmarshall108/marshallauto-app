import Combine
import Foundation

@MainActor
final class AppModel: ObservableObject {
    enum Screen {
        case login, verify, enrollment, onboarding, dashboard
    }

    @Published var screen: Screen = .login
    @Published var dashboard: Dashboard?
    @Published var busy = false
    @Published var error: String?
    private let api = API()

    func login(username: String, password: String) async {
        await run {
            let response = try await api.post("/admin/mobile/login", values: [
                "username": username, "password": password,
            ])
            try await apply(response.state)
        }
    }

    func verify(code: String) async {
        await run {
            let response = try await api.post("/admin/mobile/verify", values: ["code": code])
            try await apply(response.state)
        }
    }

    func refresh() async {
        await run {
            let state = try await api.currentSession()
            guard state.authenticated else {
                dashboard = nil
                screen = .login
                throw APIError.server("Your session has expired. Sign in again.")
            }
            if state.needsOnboarding {
                screen = .onboarding
                return
            }
            dashboard = try await api.dashboard()
            screen = .dashboard
        }
    }

    func logout() async {
        await run {
            _ = try await api.post("/admin/mobile/logout", values: [:])
            dashboard = nil
            screen = .login
        }
    }

    private func apply(_ state: String) async throws {
        switch state {
        case "verify": screen = .verify
        case "enroll": screen = .enrollment
        case "onboarding": screen = .onboarding
        case "authenticated":
            dashboard = try await api.dashboard()
            screen = .dashboard
        default: throw APIError.invalidResponse
        }
    }

    private func run(_ action: () async throws -> Void) async {
        guard !busy else { return }
        busy = true
        error = nil
        defer { busy = false }
        do {
            try await action()
        } catch {
            self.error = error.localizedDescription
        }
    }
}
