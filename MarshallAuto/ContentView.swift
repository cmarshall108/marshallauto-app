import SwiftUI
import Charts

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
                        dashboardView(dashboard)
                    }
                }
            }
            .navigationTitle("Marshall Auto Admin")
            .navigationBarTitleDisplayMode(.inline)
            .disabled(model.busy)
            .overlay {
                if model.busy {
                    ProgressView().padding().background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
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
        Form {
            Section("Staff sign in") {
                TextField("Username", text: $username)
                    .textContentType(.username)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                SecureField("Password", text: $password)
                    .textContentType(.password)
                Button("Sign in") {
                    let submittedPassword = password
                    password = ""
                    Task { await model.login(username: username, password: submittedPassword) }
                }
                .disabled(username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || password.isEmpty)
            }
            Section {
                Text("Use your existing staff account. Two-factor authentication may be required.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var verificationView: some View {
        Form {
            Section("Authenticator or recovery code") {
                TextField("Code", text: $code)
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

    private func dashboardView(_ data: Dashboard) -> some View {
        List {
            Section("Dashboard") {
                stat("Available vehicles", data.stats.availableVehicles)
                stat("Total vehicles", data.stats.totalVehicles)
                stat("Sold vehicles", data.stats.soldVehicles)
                stat("Pending leads", data.stats.pendingLeads)
                stat("Total leads", data.stats.totalLeads)
                stat("Service records", data.stats.serviceRecords)
                stat("CarFax reports", data.stats.carfaxReports)
                stat("Test drives out", data.stats.activeTestDrives)
                LabeledContent("Average rating", value: data.stats.avgRating.map { String(format: "%.2f", $0) } ?? "—")
                stat("Approved reviews", data.stats.reviewCount)
            }
            Section("Monthly profit and expenses · \(data.financials.periodLabel)") {
                LabeledContent("Gross profit", value: money(data.financials.kpis.grossProfit))
                LabeledContent("Revenue kept", value: money(data.financials.kpis.revenue))
                LabeledContent("Cash expenses", value: money(data.financials.kpis.expenseSpend))
                if let current = data.financials.current {
                    LabeledContent(current.label, value: money(current.grossProfit))
                }
                Chart {
                    ForEach(data.financials.charts.labels.indices, id: \.self) { index in
                        if index < data.financials.charts.profit.count,
                           index < data.financials.charts.expenseSpend.count {
                            LineMark(x: .value("Month", data.financials.charts.labels[index]),
                                     y: .value("Amount", data.financials.charts.profit[index]))
                                .foregroundStyle(by: .value("Type", "Profit"))
                            BarMark(x: .value("Month", data.financials.charts.labels[index]),
                                    y: .value("Amount", data.financials.charts.expenseSpend[index]))
                                .foregroundStyle(by: .value("Type", "Expenses"))
                        }
                    }
                }
                .frame(height: 180)
                .accessibilityLabel("Monthly profit and expenses")
            }
            Section("Recent leads") {
                if data.recentLeads.isEmpty {
                    Text("No leads yet.").foregroundStyle(.secondary)
                }
                ForEach(Array(data.recentLeads.enumerated()), id: \.offset) { _, lead in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(lead.name).font(.headline)
                            Spacer()
                            Text(lead.isRead ? "Read" : "New").font(.caption)
                        }
                        Text(lead.email)
                        if let phone = lead.phone, !phone.isEmpty { Text(phone) }
                        Text(lead.vehicle ?? "General inquiry")
                        Text(lead.createdAt.replacingOccurrences(of: "T", with: " ").prefix(16))
                    }
                    .font(.subheadline)
                }
            }
            Section("Top search terms · last 30 days") {
                if data.topSearches.isEmpty { Text("No search activity recorded yet.").foregroundStyle(.secondary) }
                ForEach(Array(data.topSearches.enumerated()), id: \.offset) { _, item in
                    LabeledContent(item.label, value: "\(item.count)")
                }
            }
            Section("Most viewed vehicles · last 30 days") {
                if data.mostViewedVehicles.isEmpty { Text("No vehicle views recorded yet.").foregroundStyle(.secondary) }
                ForEach(Array(data.mostViewedVehicles.enumerated()), id: \.offset) { _, item in
                    LabeledContent(item.title, value: "\(item.views) views")
                }
            }
        }
        .refreshable { await model.refresh() }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Sign out") { Task { await model.logout() } }
            }
        }
    }

    private func stat(_ label: String, _ value: Int) -> some View {
        LabeledContent(label, value: "\(value)")
    }

    private func money(_ value: String) -> String {
        guard let amount = Decimal(string: value, locale: Locale(identifier: "en_US_POSIX")) else {
            return value
        }
        return amount.formatted(.currency(code: "USD"))
    }
}
