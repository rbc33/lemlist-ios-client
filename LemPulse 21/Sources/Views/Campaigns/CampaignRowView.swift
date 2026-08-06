import SwiftUI

struct CampaignRowView: View {
    let campaign: Campaign

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: campaign.effectiveStatus.systemImage)
                .foregroundStyle(campaign.effectiveStatus.tint)
                .font(.title3)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 3) {
                Text(campaign.name)
                    .font(.body.weight(.medium))
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(campaign.effectiveStatus.displayName)
                        .font(.caption)
                        .foregroundStyle(campaign.effectiveStatus.tint)

                    if campaign.hasError == true {
                        Text("· errores")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }

            Spacer()
        }
        .padding(.vertical, 2)
    }
}
