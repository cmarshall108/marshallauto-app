import SwiftUI

enum Brand {
    static let navy = Color(red: 20 / 255, green: 34 / 255, blue: 56 / 255)
    static let gold = Color(red: 242 / 255, green: 188 / 255, blue: 88 / 255)
    static let background = Color(uiColor: .systemGroupedBackground)
    static let surface = Color(uiColor: .secondarySystemGroupedBackground)

    static func money(_ value: String) -> String {
        guard let amount = Decimal(string: value, locale: Locale(identifier: "en_US_POSIX")) else {
            return value
        }
        return amount.formatted(.currency(code: "USD"))
    }
}

struct BrandCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Brand.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

struct SectionHeading: View {
    let title: String
    var subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title).font(.headline)
            if let subtitle {
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityAddTraits(.isHeader)
    }
}

struct StatusBadge: View {
    let text: String
    var highlighted = false

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .foregroundStyle(highlighted ? Color.primary : Color.secondary)
            .background(highlighted ? Brand.gold.opacity(0.35) : Color.secondary.opacity(0.12), in: Capsule())
    }
}
