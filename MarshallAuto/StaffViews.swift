import SwiftUI

struct VehiclesView: View {
    @ObservedObject var model: AppModel
    @State private var status = ""

    var body: some View {
        List {
            Section {
                Picker("Status", selection: $status) {
                    Text("All").tag("")
                    Text("Available").tag("available")
                    Text("Pending").tag("pending")
                    Text("Sold").tag("sold")
                    Text("Coming soon").tag("coming_soon")
                }
            }
            if let result = model.vehicles {
                Section("Vehicles") {
                    if result.items.isEmpty {
                        Text("No vehicles found.").foregroundStyle(.secondary)
                    }
                    ForEach(result.items) { vehicle in
                        NavigationLink {
                            VehicleDetailView(vehicle: vehicle)
                        } label: {
                            HStack(spacing: 14) {
                                Image(systemName: "car.side.fill")
                                    .foregroundStyle(Brand.navy)
                                    .frame(width: 46, height: 46)
                                    .background(Brand.gold.opacity(0.65), in: RoundedRectangle(cornerRadius: 13))
                                    .accessibilityHidden(true)
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(vehicle.title).font(.headline)
                                    Text("\(Brand.money(vehicle.price)) · \(vehicle.mileage.formatted()) mi")
                                        .font(.subheadline).foregroundStyle(.secondary)
                                    StatusBadge(
                                        text: vehicle.isComingSoon ? "Coming soon" : vehicle.status.capitalized,
                                        highlighted: vehicle.status == "available"
                                    )
                                }
                            }
                            .padding(.vertical, 5)
                        }
                    }
                }
                Section {
                    HStack {
                        Button("Previous") {
                            Task { await model.loadVehicles(status: status, page: result.page - 1) }
                        }.disabled(result.page <= 1)
                        Spacer()
                        Text("Page \(result.page) of \(max(result.pages, 1))")
                        Spacer()
                        Button("Next") {
                            Task { await model.loadVehicles(status: status, page: result.page + 1) }
                        }.disabled(!result.hasNext)
                    }
                }
            }
        }
        .navigationTitle("Vehicles")
        .task(id: status) {
            model.vehicles = nil
            await model.loadVehicles(status: status)
        }
        .refreshable { await model.loadVehicles(status: status, page: model.vehicles?.page ?? 1) }
    }
}

struct VehicleDetailView: View {
    let vehicle: MobileVehicle

    var body: some View {
        List {
            LabeledContent("Status", value: vehicle.status.capitalized)
            if vehicle.isComingSoon { LabeledContent("Coming soon", value: "Yes") }
            LabeledContent("VIN", value: vehicle.vin ?? "N/A")
            LabeledContent("Stock number", value: vehicle.stockNumber ?? "N/A")
            LabeledContent("Price", value: Brand.money(vehicle.price))
            LabeledContent("Mileage", value: vehicle.mileage.formatted())
            LabeledContent("Added", value: String(vehicle.createdAt.prefix(10)))
            Section {
                Text("Editing, sale details, documents, photos and other vehicle workflows are not yet available in the app.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
        }
        .navigationTitle(vehicle.title)
    }

}

struct LeadsView: View {
    @ObservedObject var model: AppModel
    @State private var spam = false

    var body: some View {
        List {
            Section {
                Picker("Mailbox", selection: $spam) {
                    Text("Inbox").tag(false)
                    Text("Spam").tag(true)
                }.pickerStyle(.segmented)
            }
            if let result = model.leads {
                Section(spam ? "Spam (\(result.spamCount))" : "Inbox (\(result.inboxCount))") {
                    if result.items.isEmpty {
                        Text("No leads found.").foregroundStyle(.secondary)
                    }
                    ForEach(result.items) { lead in
                        NavigationLink {
                            LeadDetailView(model: model, lead: lead, spam: spam, page: result.page)
                        } label: {
                            HStack(spacing: 14) {
                                Image(systemName: "person.fill")
                                    .foregroundStyle(Brand.navy)
                                    .frame(width: 46, height: 46)
                                    .background(Brand.gold.opacity(0.65), in: RoundedRectangle(cornerRadius: 13))
                                    .accessibilityHidden(true)
                                VStack(alignment: .leading, spacing: 5) {
                                    HStack {
                                        Text(lead.name).font(.headline)
                                        Spacer()
                                        if !lead.isRead { StatusBadge(text: "New", highlighted: true) }
                                    }
                                    Text(lead.vehicle ?? "General inquiry")
                                        .font(.subheadline).foregroundStyle(.secondary)
                                    Text(lead.email).font(.caption).foregroundStyle(.secondary)
                                }
                            }
                            .padding(.vertical, 5)
                        }
                    }
                }
                Section {
                    HStack {
                        Button("Previous") {
                            Task { await model.loadLeads(spam: spam, page: result.page - 1) }
                        }.disabled(result.page <= 1)
                        Spacer()
                        Text("Page \(result.page) of \(max(result.pages, 1))")
                        Spacer()
                        Button("Next") {
                            Task { await model.loadLeads(spam: spam, page: result.page + 1) }
                        }.disabled(!result.hasNext)
                    }
                }
            }
        }
        .navigationTitle("Leads")
        .task(id: spam) {
            model.leads = nil
            await model.loadLeads(spam: spam)
        }
        .refreshable { await model.loadLeads(spam: spam, page: model.leads?.page ?? 1) }
    }
}

struct LeadDetailView: View {
    @ObservedObject var model: AppModel
    let lead: MobileLead
    let spam: Bool
    let page: Int
    @Environment(\.dismiss) private var dismiss
    @State private var confirmDelete = false

    var body: some View {
        List {
            Section("Contact") {
                LabeledContent("Name", value: lead.name)
                LabeledContent("Email", value: lead.email)
                if let phone = lead.phone, !phone.isEmpty { LabeledContent("Phone", value: phone) }
                LabeledContent("Vehicle", value: lead.vehicle ?? "General inquiry")
                LabeledContent("Received", value: String(lead.createdAt.replacingOccurrences(of: "T", with: " ").prefix(16)))
                LabeledContent("Status", value: lead.isRead ? "Read" : "New")
            }
            Section("Message") {
                Text(lead.message.flatMap { $0.isEmpty ? nil : $0 } ?? "No message")
            }
            if lead.spamScore > 0 {
                Section("Spam assessment") {
                    LabeledContent("Score", value: "\(lead.spamScore)")
                    if let reasons = lead.spamReasons { Text(reasons) }
                }
            }
            Section("Actions") {
                if !lead.isRead {
                    Button("Mark as read") { perform("read") }
                }
                Button(lead.isSpam ? "Restore to inbox" : "Mark as spam") { perform("spam") }
                Button("Delete lead", role: .destructive) { confirmDelete = true }
            }
        }
        .navigationTitle("Lead")
        .confirmationDialog("Permanently delete this lead?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive) { perform("delete") }
        }
    }

    private func perform(_ action: String) {
        Task {
            await model.updateLead(lead, action: action, spam: spam, page: page)
            if model.error == nil { dismiss() }
        }
    }
}
