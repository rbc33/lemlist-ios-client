import SwiftUI

struct MailboxRowView: View {
    let item: MailboxWithOwner
    let warmupScore: Int?

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.mailbox.isConnected ? "envelope.fill" : "envelope.badge.shield.half.filled")
                .foregroundStyle(item.mailbox.isConnected ? .blue : .orange)
                .font(.title3)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 3) {
                Text(item.mailbox.email)
                    .font(.body.weight(.medium))
                    .lineLimit(1)

                HStack(spacing: 6) {
                    if let limit = item.mailbox.dailySendLimit {
                        Text("\(limit) emails/día")
                    } else {
                        Text("Límite no disponible")
                    }
                    Text("· \(item.ownerName)")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            }

            Spacer()

            if item.mailbox.warmupActive, let warmupScore {
                ScoreGauge(score: warmupScore, size: 36)
            } else if item.mailbox.warmupActive {
                ProgressView().frame(width: 36, height: 36)
            } else {
                Text("Sin warmup")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}
