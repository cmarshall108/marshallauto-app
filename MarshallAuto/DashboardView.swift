import SwiftUI
import Charts

struct DashboardView: View {
    @ObservedObject var model: AppModel
    let data: Dashboard
    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 12)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                hero
                SectionHeading(title: "At a glance", subtitle: "Your dealership today")
                LazyVGrid(columns: columns, spacing: 12) {
                    metric("Available", value: "\(data.stats.availableVehicles)", icon: "car.front.fill")
                    metric("New leads", value: "\(data.stats.pendingLeads)", icon: "envelope.badge.fill")
                    metric("Vehicles", value: "\(data.stats.totalVehicles)", icon: "square.stack.3d.up.fill")
                    metric("Sold", value: "\(data.stats.soldVehicles)", icon: "checkmark.seal.fill")
                    metric("Total leads", value: "\(data.stats.totalLeads)", icon: "person.2.fill")
                    metric("Test drives out", value: "\(data.stats.activeTestDrives)", icon: "steeringwheel")
                    metric("Service records", value: "\(data.stats.serviceRecords)", icon: "wrench.and.screwdriver.fill")
                    metric("CarFax reports", value: "\(data.stats.carfaxReports)", icon: "doc.text.fill")
                    metric("Average rating", value: data.stats.avgRating.map { String(format: "%.2f", $0) } ?? "—", icon: "star.fill")
                    metric("Approved reviews", value: "\(data.stats.reviewCount)", icon: "text.bubble.fill")
                }
                SectionHeading(title: "Staff tools", subtitle: "Pick up where you left off")
                HStack(spacing: 12) {
                    NavigationLink { VehiclesView(model: model) } label: {
                        toolCard("Vehicles", subtitle: "Browse inventory", icon: "car.side.fill")
                    }
                    NavigationLink { LeadsView(model: model) } label: {
                        toolCard("Leads", subtitle: "Inbox & spam", icon: "tray.full.fill")
                    }
                }
                .buttonStyle(.plain)
                financialCard
                recentLeads
                activity
            }
            .padding(16)
            .frame(maxWidth: 720)
            .frame(maxWidth: .infinity)
        }
        .background(Brand.background)
        .refreshable { await model.refresh() }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Sign out") { Task { await model.logout() } }
            }
        }
    }

    private var hero: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("MARSHALL AUTO").font(.caption.weight(.heavy)).tracking(1.2).foregroundStyle(Brand.gold)
                Text("The lot, at a glance.").font(.title2.bold()).foregroundStyle(.white)
                Text("Your staff dashboard").font(.subheadline).foregroundStyle(.white.opacity(0.8))
            }
            Spacer(minLength: 0)
            Image(systemName: "car.side.fill")
                .font(.largeTitle).foregroundStyle(Brand.gold)
                .accessibilityHidden(true)
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(colors: [Brand.navy, Color(red: 38 / 255, green: 61 / 255, blue: 85 / 255)],
                           startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 22, style: .continuous)
        )
    }

    private func metric(_ title: String, value: String, icon: String) -> some View {
        BrandCard {
            VStack(alignment: .leading, spacing: 9) {
                Image(systemName: icon)
                    .foregroundStyle(Brand.gold)
                    .accessibilityHidden(true)
                Text(value).font(.title2.bold()).monospacedDigit()
                Text(title).font(.caption).foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title), \(value)")
    }

    private func toolCard(_ title: String, subtitle: String, icon: String) -> some View {
        BrandCard {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: icon).foregroundStyle(Brand.gold).font(.title3)
                Text(title).font(.headline)
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, minHeight: 76, alignment: .leading)
        }
    }

    private var financialCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeading(title: "Financial overview", subtitle: data.financials.periodLabel)
            BrandCard {
                VStack(alignment: .leading, spacing: 14) {
                    Text("GROSS PROFIT").font(.caption.weight(.bold)).foregroundStyle(.secondary)
                    Text(Brand.money(data.financials.kpis.grossProfit)).font(.title2.bold())
                    LabeledContent("Revenue kept", value: Brand.money(data.financials.kpis.revenue))
                    LabeledContent("Cash expenses", value: Brand.money(data.financials.kpis.expenseSpend))
                    if let current = data.financials.current {
                        LabeledContent(current.label, value: Brand.money(current.grossProfit))
                    }
                    Chart {
                        ForEach(data.financials.charts.labels.indices, id: \.self) { index in
                            if index < data.financials.charts.profit.count,
                               index < data.financials.charts.revenue.count,
                               index < data.financials.charts.expenseSpend.count {
                                LineMark(x: .value("Month", data.financials.charts.labels[index]),
                                         y: .value("Amount", data.financials.charts.profit[index]))
                                    .foregroundStyle(by: .value("Type", "Profit"))
                                BarMark(x: .value("Month", data.financials.charts.labels[index]),
                                        y: .value("Amount", data.financials.charts.revenue[index]))
                                    .foregroundStyle(by: .value("Type", "Revenue"))
                                    .position(by: .value("Type", "Revenue"))
                                BarMark(x: .value("Month", data.financials.charts.labels[index]),
                                        y: .value("Amount", data.financials.charts.expenseSpend[index]))
                                    .foregroundStyle(by: .value("Type", "Expenses"))
                                    .position(by: .value("Type", "Expenses"))
                            }
                        }
                    }
                    .chartForegroundStyleScale(["Profit": Color.green, "Revenue": Color.blue, "Expenses": Color.orange])
                    .frame(height: 190)
                    .accessibilityLabel("Monthly profit, revenue and expenses")
                }
                .font(.subheadline)
            }
        }
    }

    private var recentLeads: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeading(title: "Recent leads", subtitle: "The latest customer inquiries")
            BrandCard {
                if data.recentLeads.isEmpty {
                    Text("No leads yet.").foregroundStyle(.secondary)
                } else {
                    VStack(alignment: .leading, spacing: 14) {
                        ForEach(Array(data.recentLeads.enumerated()), id: \.offset) { index, lead in
                            if index > 0 { Divider() }
                            VStack(alignment: .leading, spacing: 5) {
                                HStack(alignment: .top) {
                                    Text(lead.name).font(.headline)
                                    Spacer()
                                    StatusBadge(text: lead.isRead ? "Read" : "New", highlighted: !lead.isRead)
                                }
                                Text(lead.vehicle ?? "General inquiry").font(.subheadline)
                                Text(lead.email).font(.subheadline).foregroundStyle(.secondary)
                                if let phone = lead.phone, !phone.isEmpty {
                                    Text(phone).font(.subheadline).foregroundStyle(.secondary)
                                }
                                Text(lead.createdAt.replacingOccurrences(of: "T", with: " ").prefix(16))
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
    }

    private var activity: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeading(title: "Customer activity", subtitle: "Last 30 days")
            BrandCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Top search terms").font(.headline)
                    if data.topSearches.isEmpty {
                        Text("No search activity recorded yet.").foregroundStyle(.secondary)
                    }
                    ForEach(Array(data.topSearches.enumerated()), id: \.offset) { _, item in
                        LabeledContent(item.label, value: "\(item.count)")
                    }
                    Divider()
                    Text("Most viewed vehicles").font(.headline)
                    if data.mostViewedVehicles.isEmpty {
                        Text("No vehicle views recorded yet.").foregroundStyle(.secondary)
                    }
                    ForEach(Array(data.mostViewedVehicles.enumerated()), id: \.offset) { _, item in
                        LabeledContent(item.title, value: "\(item.views) views")
                    }
                }
                .font(.subheadline)
            }
        }
    }
}
