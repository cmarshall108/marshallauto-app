import Combine
import Foundation

@MainActor
final class AppModel: ObservableObject {
    enum Screen {
        case login, verify, enrollment, onboarding, dashboard
    }

    @Published var screen: Screen = .login
    @Published var dashboard: Dashboard?
    @Published var vehicles: VehiclePage?
    @Published var leads: LeadPage?
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
                vehicles = nil
                leads = nil
                screen = .login
                throw APIError.server("Your session has expired. Sign in again.")
            }

            func loadVehicles(status: String, page: Int = 1) async {
                await run {
                    vehicles = try await api.get("/admin/mobile/vehicles?status=\(status)&page=\(page)")
                }
            }

            func loadLeads(spam: Bool, page: Int = 1) async {
                await run {
                    leads = try await api.get("/admin/mobile/leads?view=\(spam ? "spam" : "inbox")&page=\(page)")
                }
            }

            func updateLead(_ lead: MobileLead, action: String, spam: Bool, page: Int) async {
                await run {
                    _ = try await api.post("/admin/mobile/leads/\(lead.id)/\(action)", values: [:])
                    let mailbox = spam ? "spam" : "inbox"
                    let updated: LeadPage = try await api.get("/admin/mobile/leads?view=\(mailbox)&page=\(page)")
                    if updated.items.isEmpty && page > 1 {
                        leads = try await api.get("/admin/mobile/leads?view=\(mailbox)&page=\(page - 1)")
                    } else {
                        leads = updated
                    }
                }
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

    private func run(_ action: @MainActor () async throws -> Void) async {
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
