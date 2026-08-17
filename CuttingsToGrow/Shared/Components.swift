import SwiftUI

/// A small rounded label used for tags — difficulty, medium, pet-safety, etc.
struct TagPill: View {
    let text: String
    let systemImage: String
    let color: Color

    var body: some View {
        Label(text, systemImage: systemImage)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(color.opacity(0.15), in: Capsule())
            .foregroundStyle(color)
    }
}

/// A titled content card — the workhorse container across the app.
struct SectionCard<Content: View>: View {
    let title: String
    let systemImage: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: systemImage)
                .font(.headline)
                .foregroundStyle(Theme.leaf)
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
    }
}

/// The flagship pet-safety badge, driven entirely by `ToxicityInfo`.
///
/// Three states, never ambiguous: known-toxic (red), unverified (amber), or
/// confirmed safe (green). "Unknown" is treated as a caution, never as safe.
struct ToxicityBadge: View {
    let toxicity: ToxicityInfo

    var body: some View {
        if toxicity.isToxicToAnyPet {
            TagPill(text: toxicity.headline, systemImage: "pawprint.fill", color: Theme.warning)
        } else if toxicity.verify {
            TagPill(text: "Pet safety unverified", systemImage: "pawprint", color: Theme.caution)
        } else {
            TagPill(text: "Pet safe", systemImage: "pawprint", color: Theme.sprout)
        }
    }
}

/// One row in a "how it works" list, used on the Phase-0 placeholder screens.
struct FlowStep: View {
    let number: Int
    let title: String
    let detail: String
    let systemImage: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(Theme.leaf)
                .frame(width: 34, height: 34)
                .background(Theme.sprout.opacity(0.18), in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text("\(number). \(title)").font(.subheadline.weight(.semibold))
                Text(detail).font(.caption).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
    }
}

/// A subtle "coming in a later phase" note, so Phase-0 screens are honest about
/// what's a scaffold and what's live.
struct ComingSoonNote: View {
    let text: String

    var body: some View {
        Label(text, systemImage: "hammer.fill")
            .font(.caption)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 12))
    }
}
