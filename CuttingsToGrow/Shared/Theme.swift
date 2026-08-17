import SwiftUI
import UIKit // for the adaptive UIColor system backgrounds below

/// The Cuttings Garden design system: a calm, neutral canvas with plant-forward
/// accents, plus a deliberately high-contrast safety colour so pet-toxicity
/// warnings are never missed.
///
/// Colours are defined in code so Phase 0 needs no asset catalog. Adaptive
/// surfaces use the system grouped-background colours, which follow light/dark
/// automatically; the branded accents read well on both. Full dark-mode tuning
/// and the app icon land in Phase 5.
enum Theme {
    // Brand accents
    static let leaf = Color(red: 0.20, green: 0.52, blue: 0.34)
    static let sprout = Color(red: 0.53, green: 0.75, blue: 0.44)
    static let soil = Color(red: 0.36, green: 0.27, blue: 0.20)
    static let terracotta = Color(red: 0.80, green: 0.46, blue: 0.33)
    static let water = Color(red: 0.29, green: 0.57, blue: 0.75)

    /// Safety-critical warning colour (pet toxicity). High-contrast on purpose.
    static let warning = Color(red: 0.80, green: 0.23, blue: 0.20)
    /// Amber for "check this fact" (`verify`) flags.
    static let caution = Color(red: 0.78, green: 0.55, blue: 0.12)

    // Adaptive surfaces (follow light/dark automatically)
    static let groupedBackground = Color(.systemGroupedBackground)
    static let cardBackground = Color(.secondarySystemGroupedBackground)

    static let cardRadius: CGFloat = 16

    /// Accent colour for a difficulty level.
    static func color(for difficulty: Difficulty) -> Color {
        switch difficulty {
        case .beginner: return sprout
        case .intermediate: return terracotta
        case .advanced: return warning
        }
    }
}
