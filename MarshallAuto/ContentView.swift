import SwiftUI

struct ContentView: View {
    @ObservedObject var model: AppModel
    @State private var username = ""
    @State private var password = ""
    @State private var code = ""

    var body: some View {
        NavigationStack {
            Group {
                switch model.screen {
                case .login:
                    loginView
                case .verify:
                    verificationView
                case .enrollment:
                    setupView(
                        title: "Set up two-factor authentication",
                        message: "Complete authenticator setup and save your recovery codes on the website. Then return here and sign in again."
                    )
                case .onboarding:
                    setupView(
                        title: "Complete your staff profile",
                        message: "Complete your profile and change your temporary password on the website. Then return here and sign in again."
                    )
                case .dashboard:
                    if let dashboard = model.dashboard {
                        DashboardView(model: model, data: dashboard)
                    }
                }
            }
            .navigationTitle(model.screen == .dashboard ? "Dashboard" : "Staff access")
            .navigationBarTitleDisplayMode(.inline)
            .tint(.primary)
            .disabled(model.busy)
            .overlay {
                if model.busy {
                    ProgressView("Loading")
                        .padding()
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                }
            }
            .alert("Unable to continue", isPresented: Binding(
                get: { model.error != nil },
                set: { if !$0 { model.error = nil } }
            )) {
                Button("OK", role: .cancel) { model.error = nil }
            } message: {
                Text(model.error ?? "")
            }
        }
    }

    private var loginView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                brandHeader
                VStack(alignment: .leading, spacing: 6) {
                    Text("Welcome back").font(.largeTitle.bold())
                    Text("Sign in to your staff account to manage your day.")
                        .foregroundStyle(.secondary)
                }
                BrandCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("STAFF SIGN IN")
                            .font(.caption.weight(.bold)).foregroundStyle(.secondary)
                        TextField("Username", text: $username)
                            .textContentType(.username)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .padding(14)
                            .background(Brand.background, in: RoundedRectangle(cornerRadius: 12))
                        SecureField("Password", text: $password)
                            .textContentType(.password)
                            .padding(14)
                            .background(Brand.background, in: RoundedRectangle(cornerRadius: 12))
                        Button {
                            let submittedPassword = password
                            password = ""
                            Task { await model.login(username: username, password: submittedPassword) }
                        } label: {
                            Label("Sign in", systemImage: "arrow.right")
                                .frame(maxWidth: .infinity).padding(.vertical, 7)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Brand.navy)
                        .disabled(username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || password.isEmpty)
                    }
                }
                Label("Your account is protected with staff authentication.", systemImage: "lock.shield")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            .padding(20)
            .frame(maxWidth: 520)
            .frame(maxWidth: .infinity)
        }
        .background(Brand.background)
    }

    private var brandHeader: some View {
        HStack(spacing: 14) {
            Image(systemName: "car.front.fill")
                .font(.title2)
                .foregroundStyle(Brand.navy)
                .frame(width: 50, height: 50)
                .background(Brand.gold, in: RoundedRectangle(cornerRadius: 15))
            VStack(alignment: .leading, spacing: 2) {
                Text("MARSHALL AUTO").font(.headline.weight(.heavy))
                Text("STAFF COMPANION").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            }
        }
        .padding(.top, 24)
    }

    private var verificationView: some View {
        Form {
            Section {
                Label("Verify your identity", systemImage: "lock.shield")
                    .font(.headline)
                Text("Enter your authenticator code or an unused recovery code.")
                    .font(.subheadline).foregroundStyle(.secondary)
                TextField("Authenticator or recovery code", text: $code)
                    .textContentType(.oneTimeCode)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                Button("Verify") {
                    let submittedCode = code
                    code = ""
                    Task { await model.verify(code: submittedCode) }
                }
                .disabled(code.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            Button("Start over") {
                code = ""
                model.screen = .login
            }
        }
    }

    private func setupView(title: String, message: String) -> some View {
        Form {
            Section(title) {
                Text(message)
                Link("Open staff website", destination: API.baseURL.appendingPathComponent("admin/login"))
                Button("Return to sign in") {
                    if model.screen == .onboarding {
                        Task { await model.logout() }
                    } else {
                        model.screen = .login
                    }
                }
            }
        }
    }
}
