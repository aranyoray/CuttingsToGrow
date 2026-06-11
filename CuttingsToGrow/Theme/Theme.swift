import SwiftUI

/// Design system for CuttingsToGrow — warm botanical palette with high-contrast
/// safety accents so toxicity warnings are never missed.
enum Theme {
    static let leaf = Color(red: 0.18, green: 0.55, blue: 0.34)
    static let sprout = Color(red: 0.55, green: 0.78, blue: 0.45)
    static let soil = Color(red: 0.36, green: 0.27, blue: 0.20)
    static let terracotta = Color(red: 0.80, green: 0.45, blue: 0.32)
    static let cream = Color(red: 0.98, green: 0.96, blue: 0.91)
    static let warning = Color(red: 0.85, green: 0.25, blue: 0.22)
    static let water = Color(red: 0.33, green: 0.62, blue: 0.78)

    static let cardBackground = Color(.secondarySystemGroupedBackground)
}

struct TagPill: View {
    let text: String
    let icon: String
    let color: Color

    var body: some View {
        Label(text, systemImage: icon)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(color.opacity(0.15), in: Capsule())
            .foregroundStyle(color)
    }
}

struct SectionCard<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundStyle(Theme.leaf)
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 16))
    }
}
