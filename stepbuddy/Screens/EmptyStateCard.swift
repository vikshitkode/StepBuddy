//
//  EmptyStateCard.swift
//  stepbuddy
//
//  Created by Sai Vikshit Kode on 9/20/25.
//

import SwiftUI

struct EmptyStateCard: View {
    var title: String
    var message: String
    var color: Color

    var body: some View {
        VStack(spacing: 10) {
            Text(title).font(.headline).foregroundStyle(color)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.tertiarySystemBackground)))
    }
}

#Preview {
    EmptyStateCard(title: "Empty State", message: "There is nothing here.", color: .indigo)
}
