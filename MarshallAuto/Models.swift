import Foundation

struct Dashboard: Decodable {
    struct Stats: Decodable {
        let totalVehicles: Int
        let availableVehicles: Int
        let soldVehicles: Int
        let pendingLeads: Int
        let totalLeads: Int
        let serviceRecords: Int
        let carfaxReports: Int
        let activeTestDrives: Int
        let avgRating: Double?
        let reviewCount: Int
    }
    struct Lead: Decodable, Identifiable {
        let createdAt: String
        let name: String
        let email: String
        let phone: String?
        let vehicle: String?
        let isRead: Bool
        var id: String { "\(createdAt)-\(email)" }
    }
    struct Search: Decodable {
        let label: String
        let count: Int
    }
    struct ViewedVehicle: Decodable {
        let title: String
        let views: Int
    }
    struct Financials: Decodable {
        struct KPIs: Decodable {
            let grossProfit: String
            let revenue: String
            let expenseSpend: String
        }
        struct Current: Decodable {
            let label: String
            let grossProfit: String
        }
        struct Chart: Decodable {
            let labels: [String]
            let profit: [Double]
            let expenseSpend: [Double]
        }
        let periodLabel: String
        let kpis: KPIs
        let current: Current?
        let charts: Chart
    }
    let stats: Stats
    let recentLeads: [Lead]
    let topSearches: [Search]
    let mostViewedVehicles: [ViewedVehicle]
    let financials: Financials
}
