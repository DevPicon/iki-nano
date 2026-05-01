//
//  MainMenuView.swift
//  ikinano
//

import SwiftUI

struct MainMenuView: View {
    let onCapabilitySelected: (InferenceCapability) -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Iki Nano")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.horizontal)

                    Text("On-device AI with Gemma 2B")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)

                    Divider()
                        .padding(.vertical, 8)

                    VStack(spacing: 12) {
                        CapabilityCard(
                            capability: .summarization,
                            icon: "doc.text.fill",
                            onTap: { onCapabilitySelected(.summarization) }
                        )

                        CapabilityCard(
                            capability: .proofreading,
                            icon: "text.badge.checkmark",
                            onTap: { onCapabilitySelected(.proofreading) }
                        )

                        CapabilityCard(
                            capability: .rewriteFormal,
                            icon: "text.badge.star",
                            onTap: { onCapabilitySelected(.rewriteFormal) }
                        )

                        CapabilityCard(
                            capability: .rewriteCasual,
                            icon: "text.bubble.fill",
                            onTap: { onCapabilitySelected(.rewriteCasual) }
                        )

                        CapabilityCard(
                            capability: .rewriteConcise,
                            icon: "text.alignleft",
                            onTap: { onCapabilitySelected(.rewriteConcise) }
                        )
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct CapabilityCard: View {
    let capability: InferenceCapability
    let icon: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.blue)
                    .frame(width: 40)

                VStack(alignment: .leading, spacing: 4) {
                    Text(capability.displayName)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    Text(capability.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    MainMenuView(onCapabilitySelected: { _ in })
}
