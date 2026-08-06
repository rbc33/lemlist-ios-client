import SwiftUI

extension CampaignStatus {
    var tint: Color {
        switch self {
        case .running: return .green
        case .paused: return .orange
        case .draft: return .gray
        case .ended: return .blue
        case .archived: return .secondary
        case .errors: return .red
        case .unknown: return .gray
        }
    }
}

/// Circular score gauge used for the lemwarm deliverability score (0–100).
struct ScoreGauge: View {
    let score: Int
    var size: CGFloat = 54

    private var fraction: Double { Double(min(max(score, 0), 100)) / 100 }

    private var tint: Color {
        switch score {
        case ..<50: return .red
        case 50..<80: return .orange
        default: return .green
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(tint.opacity(0.2), lineWidth: 5)
            Circle()
                .trim(from: 0, to: fraction)
                .stroke(tint, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(score)")
                .font(.system(size: size * 0.32, weight: .semibold, design: .rounded))
        }
        .frame(width: size, height: size)
        .accessibilityLabel("Puntuación de warmup: \(score) de 100")
    }
}
